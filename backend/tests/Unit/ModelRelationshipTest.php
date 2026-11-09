<?php

namespace Tests\Unit;

use App\Models\CareLog;
use App\Models\Plant;
use App\Models\PlantCategory;
use App\Models\Reminder;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ModelRelationshipTest extends TestCase
{
    use RefreshDatabase;

    public function test_relationships(): void
    {
        $user = User::factory()->create();
        $category = PlantCategory::factory()->create();
        $plant = Plant::factory()->for($user)->create(['plant_category_id' => $category->id]);
        $reminder = Reminder::factory()->create(['user_id' => $user->id, 'plant_id' => $plant->id]);
        $log = CareLog::factory()->create(['user_id' => $user->id, 'plant_id' => $plant->id]);

        $this->assertTrue($user->plants->contains($plant));
        $this->assertTrue($user->reminders->contains($reminder));
        $this->assertTrue($user->careLogs->contains($log));
        $this->assertTrue($plant->user->is($user));
        $this->assertTrue($plant->category->is($category));
        $this->assertTrue($plant->reminders->contains($reminder));
        $this->assertTrue($plant->careLogs->contains($log));
        $this->assertTrue($category->plants->contains($plant));
        $this->assertTrue($reminder->plant->is($plant));
        $this->assertTrue($log->user->is($user));
    }

    public function test_casts(): void
    {
        $plant = Plant::factory()->create();
        $reminder = Reminder::factory()->create();

        $this->assertInstanceOf(\Carbon\Carbon::class, $plant->next_watering_at);
        $this->assertIsInt($plant->watering_interval_days);
        $this->assertIsBool($reminder->is_completed);
    }

    public function test_deleting_category_keeps_plants(): void
    {
        $category = PlantCategory::factory()->create();
        $plant = Plant::factory()->create(['plant_category_id' => $category->id]);
        $category->delete();

        $this->assertNull($plant->fresh()->plant_category_id);
    }

    public function test_deleting_plant_cascades(): void
    {
        $plant = Plant::factory()->create();
        Reminder::factory()->create(['user_id' => $plant->user_id, 'plant_id' => $plant->id]);
        $plant->delete();

        $this->assertDatabaseCount('reminders', 0);
    }

    public function test_user_password_is_hashed(): void
    {
        $user = User::factory()->create(['password' => 'plain-text']);
        $this->assertNotSame('plain-text', $user->password);
    }
}
