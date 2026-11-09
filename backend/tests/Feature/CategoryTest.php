<?php

namespace Tests\Feature;

use App\Models\PlantCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CategoryTest extends TestCase
{
    use RefreshDatabase;

    public function test_any_user_can_list_categories(): void
    {
        Sanctum::actingAs(User::factory()->create());
        PlantCategory::factory()->count(3)->create();

        $this->getJson('/api/v1/categories')->assertOk()->assertJsonCount(3, 'data');
    }

    public function test_only_admins_can_modify_categories(): void
    {
        $admin = User::factory()->create(['email' => 'admin@example.com']);
        config(['plantcare.category_admin_emails' => ['admin@example.com']]);

        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/v1/categories', ['name' => 'Herbs'])->assertForbidden();

        Sanctum::actingAs($admin);
        $id = $this->postJson('/api/v1/categories', ['name' => 'Herbs', 'color' => '#00AA00'])->assertCreated()->assertJsonPath('data.slug', 'herbs')->json('data.id');
        $this->putJson("/api/v1/categories/{$id}", ['name' => 'Kitchen Herbs'])->assertOk();
        $this->deleteJson("/api/v1/categories/{$id}")->assertOk();
    }

    public function test_category_validation(): void
    {
        $admin = User::factory()->create(['email' => 'admin@example.com']);
        config(['plantcare.category_admin_emails' => ['admin@example.com']]);
        Sanctum::actingAs($admin);

        $this->postJson('/api/v1/categories', ['name' => '', 'color' => 'green'])->assertStatus(422)->assertJsonValidationErrors(['name', 'color']);
    }
}
