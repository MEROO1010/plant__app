<?php

namespace Tests\Feature;

use App\Models\CareLog;
use App\Models\Plant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CareLogTest extends TestCase
{
    use RefreshDatabase;

    public function test_create_list_and_filter_care_logs(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        $plant = Plant::factory()->for($user)->create();

        $this->postJson('/api/v1/care-logs', ['plant_id' => $plant->id, 'type' => 'pruning', 'notes' => 'Trimmed'])->assertCreated();
        $this->postJson('/api/v1/care-logs', ['plant_id' => $plant->id, 'type' => 'watering'])->assertCreated();
        CareLog::factory()->create(); // someone else's

        $this->getJson('/api/v1/care-logs')->assertJsonPath('meta.total', 2);
        $this->getJson('/api/v1/care-logs?type=pruning')->assertJsonPath('meta.total', 1);
        $this->getJson("/api/v1/plants/{$plant->id}/care-logs")->assertOk()->assertJsonPath('meta.total', 2);
    }

    public function test_cannot_log_for_another_users_plant(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $other = Plant::factory()->create();

        $this->postJson('/api/v1/care-logs', ['plant_id' => $other->id, 'type' => 'watering'])->assertStatus(422);
        $this->getJson("/api/v1/plants/{$other->id}/care-logs")->assertForbidden();
    }
}
