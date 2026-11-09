<?php

namespace Tests\Feature;

use App\Models\Plant;
use App\Models\Reminder;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StatisticsTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_summarises_user_data(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        $healthy = Plant::factory()->for($user)->create(['next_watering_at' => now()->addDays(5)]);
        $sick = Plant::factory()->for($user)->create(['name' => 'Sicky', 'health_status' => 'critical']);
        Plant::factory()->create(); // other user

        Reminder::factory()->create(['user_id' => $user->id, 'plant_id' => $healthy->id, 'due_at' => now()->setTime(12, 0)]);
        Reminder::factory()->create(['user_id' => $user->id, 'plant_id' => $sick->id, 'due_at' => now()->addDays(2)]);

        $res = $this->getJson('/api/v1/statistics/dashboard')->assertOk();
        $res->assertJsonPath('data.total_plants', 2)
            ->assertJsonPath('data.tasks_due_today', 1)
            ->assertJsonPath('data.featured_plant.name', 'Sicky')
            ->assertJsonCount(1, 'data.upcoming_reminders')
            ->assertJsonStructure(['data' => ['weekly_progress' => ['completion_percentage', 'days']]]);
    }

    public function test_weekly_progress_counts_completion(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        $plant = Plant::factory()->for($user)->create();
        $due = now()->startOfWeek()->addHours(8);
        Reminder::factory()->create(['user_id' => $user->id, 'plant_id' => $plant->id, 'due_at' => $due, 'is_completed' => true, 'completed_at' => $due]);
        Reminder::factory()->create(['user_id' => $user->id, 'plant_id' => $plant->id, 'due_at' => $due, 'is_completed' => false]);

        $this->getJson('/api/v1/statistics/weekly-progress')->assertOk()
            ->assertJsonPath('data.tasks_due', 2)->assertJsonPath('data.tasks_completed', 1)
            ->assertJsonPath('data.completion_percentage', 50)->assertJsonCount(7, 'data.days');
    }

    public function test_plant_health_breakdown(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        Plant::factory()->for($user)->count(3)->create();
        Plant::factory()->for($user)->create(['health_status' => 'critical']);

        $this->getJson('/api/v1/statistics/plant-health')->assertOk()
            ->assertJsonPath('data.total', 4)->assertJsonPath('data.breakdown.healthy', 3)
            ->assertJsonPath('data.breakdown.critical', 1)->assertJsonPath('data.healthy_percentage', 75);
    }

    public function test_statistics_require_auth(): void
    {
        $this->getJson('/api/v1/statistics/dashboard')->assertUnauthorized();
    }
}
