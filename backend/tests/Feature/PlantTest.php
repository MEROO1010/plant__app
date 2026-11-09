<?php

namespace Tests\Feature;

use App\Models\Plant;
use App\Models\PlantCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PlantTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
    }

    public function test_can_create_plant_and_schedule_reminders(): void
    {
        $cat = PlantCategory::factory()->create();

        $res = $this->postJson('/api/v1/plants', [
            'name' => 'Monty', 'species' => 'Monstera', 'plant_category_id' => $cat->id,
            'watering_interval_days' => 7, 'fertilizing_interval_days' => 30,
        ]);

        $res->assertCreated()->assertJsonPath('data.name', 'Monty')->assertJsonPath('data.category.id', $cat->id);
        $plant = Plant::first();
        $this->assertSame($this->user->id, $plant->user_id);
        $this->assertNotNull($plant->next_watering_at);
        $this->assertDatabaseHas('reminders', ['plant_id' => $plant->id, 'type' => 'watering', 'is_completed' => false]);
        $this->assertDatabaseHas('reminders', ['plant_id' => $plant->id, 'type' => 'fertilizing']);
    }

    public function test_index_is_paginated_searchable_and_filterable(): void
    {
        $cat = PlantCategory::factory()->create();
        Plant::factory()->for($this->user)->create(['name' => 'Fern', 'species' => 'Nephrolepis', 'plant_category_id' => $cat->id]);
        Plant::factory()->for($this->user)->create(['name' => 'Cactus', 'species' => 'Opuntia', 'health_status' => 'critical']);
        Plant::factory()->count(2)->create(); // other users' plants must never appear

        $this->getJson('/api/v1/plants')->assertOk()->assertJsonPath('meta.total', 2);
        $this->getJson('/api/v1/plants?search=nephro')->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.name', 'Fern');
        $this->getJson('/api/v1/plants?category_id='.$cat->id)->assertJsonPath('meta.total', 1);
        $this->getJson('/api/v1/plants?health_status=critical')->assertJsonPath('data.0.name', 'Cactus');
        $this->getJson('/api/v1/plants?per_page=1')->assertJsonPath('meta.last_page', 2);
    }

    public function test_index_sorts_by_next_watering(): void
    {
        Plant::factory()->for($this->user)->create(['name' => 'Later', 'next_watering_at' => now()->addDays(5)]);
        Plant::factory()->for($this->user)->create(['name' => 'Sooner', 'next_watering_at' => now()->addDay()]);

        $this->getJson('/api/v1/plants')->assertJsonPath('data.0.name', 'Sooner');
    }

    public function test_can_update_and_delete_plant(): void
    {
        $plant = Plant::factory()->for($this->user)->create();

        $this->putJson("/api/v1/plants/{$plant->id}", ['name' => 'Renamed', 'health_status' => 'needs_attention'])
            ->assertOk()->assertJsonPath('data.name', 'Renamed');
        $this->assertDatabaseHas('plants', ['id' => $plant->id, 'health_status' => 'needs_attention']);

        $this->deleteJson("/api/v1/plants/{$plant->id}")->assertOk();
        $this->assertDatabaseMissing('plants', ['id' => $plant->id]);
    }

    public function test_water_updates_schedule_logs_and_rolls_reminder(): void
    {
        $plant = Plant::factory()->for($this->user)->create(['watering_interval_days' => 4, 'next_watering_at' => now()->subDay()]);
        $old = \App\Models\Reminder::factory()->create(['user_id' => $this->user->id, 'plant_id' => $plant->id, 'type' => 'watering', 'due_at' => now()->subDay()]);

        $this->postJson("/api/v1/plants/{$plant->id}/water", ['notes' => 'Deep soak'])->assertOk();

        $plant->refresh();
        $this->assertTrue($plant->next_watering_at->isAfter(now()->addDays(3)));
        $this->assertDatabaseHas('care_logs', ['plant_id' => $plant->id, 'type' => 'watering', 'notes' => 'Deep soak']);
        $this->assertTrue($old->fresh()->is_completed);
    }

    public function test_fertilize_and_rotate_create_care_logs(): void
    {
        $plant = Plant::factory()->for($this->user)->create();

        $this->postJson("/api/v1/plants/{$plant->id}/fertilize")->assertOk();
        $this->postJson("/api/v1/plants/{$plant->id}/rotate")->assertOk();

        $this->assertDatabaseHas('care_logs', ['plant_id' => $plant->id, 'type' => 'fertilizing']);
        $this->assertDatabaseHas('care_logs', ['plant_id' => $plant->id, 'type' => 'rotating']);
        $this->getJson("/api/v1/plants/{$plant->id}/care-history")->assertOk()->assertJsonPath('meta.total', 2);
    }

    public function test_image_upload_is_validated(): void
    {
        Storage::fake('public');

        $this->postJson('/api/v1/plants', ['name' => 'A', 'image' => UploadedFile::fake()->image('p.jpg')])->assertCreated();
        $this->postJson('/api/v1/plants', ['name' => 'B', 'image' => UploadedFile::fake()->create('evil.php', 10)])
            ->assertStatus(422)->assertJsonValidationErrors('image');
        $this->postJson('/api/v1/plants', ['name' => 'C', 'image' => UploadedFile::fake()->image('big.jpg')->size(5000)])
            ->assertStatus(422)->assertJsonValidationErrors('image');
    }

    public function test_validation_errors_use_standard_envelope(): void
    {
        $this->postJson('/api/v1/plants', ['watering_interval_days' => 0, 'health_status' => 'zombie'])
            ->assertStatus(422)->assertJsonPath('success', false)
            ->assertJsonValidationErrors(['name', 'watering_interval_days', 'health_status']);
    }

    public function test_user_cannot_access_another_users_plant(): void
    {
        $other = Plant::factory()->create();

        $this->getJson("/api/v1/plants/{$other->id}")->assertForbidden();
        $this->putJson("/api/v1/plants/{$other->id}", ['name' => 'Hacked'])->assertForbidden();
        $this->deleteJson("/api/v1/plants/{$other->id}")->assertForbidden();
        $this->postJson("/api/v1/plants/{$other->id}/water")->assertForbidden();
        $this->getJson("/api/v1/plants/{$other->id}/care-history")->assertForbidden();
        $this->assertDatabaseHas('plants', ['id' => $other->id, 'name' => $other->name]);
    }

    public function test_user_id_cannot_be_mass_assigned(): void
    {
        $other = User::factory()->create();
        $this->postJson('/api/v1/plants', ['name' => 'Mine', 'user_id' => $other->id])->assertCreated();

        $this->assertSame($this->user->id, Plant::first()->user_id);
    }

    public function test_missing_plant_returns_404_envelope(): void
    {
        $this->getJson('/api/v1/plants/99999')->assertNotFound()->assertJsonPath('success', false);
    }
}
