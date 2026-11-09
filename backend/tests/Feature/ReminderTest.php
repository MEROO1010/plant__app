<?php

namespace Tests\Feature;

use App\Models\Plant;
use App\Models\Reminder;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReminderTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
    }

    public function test_can_create_reminder_for_own_plant(): void
    {
        $plant = Plant::factory()->for($this->user)->create();

        $this->postJson('/api/v1/reminders', [
            'plant_id' => $plant->id, 'type' => 'pruning', 'title' => 'Prune', 'due_at' => now()->addDays(2)->toIso8601String(),
        ])->assertCreated()->assertJsonPath('data.type', 'pruning');
    }

    public function test_cannot_create_reminder_for_another_users_plant(): void
    {
        $other = Plant::factory()->create();

        $this->postJson('/api/v1/reminders', ['plant_id' => $other->id, 'type' => 'pruning', 'title' => 'X', 'due_at' => now()->toIso8601String()])
            ->assertStatus(422)->assertJsonValidationErrors('plant_id');
    }

    public function test_today_and_upcoming_lists(): void
    {
        $plant = Plant::factory()->for($this->user)->create();
        $mk = fn (string $title, $due) => Reminder::factory()->create(['user_id' => $this->user->id, 'plant_id' => $plant->id, 'title' => $title, 'due_at' => $due]);
        $mk('overdue', now()->subDay());
        $mk('today', now()->setTime(12, 0));
        $mk('soon', now()->addDays(3));
        $mk('far', now()->addDays(60));

        $today = $this->getJson('/api/v1/reminders/today')->assertOk()->json('data');
        $this->assertEqualsCanonicalizing(['overdue', 'today'], array_column($today, 'title'));

        $upcoming = $this->getJson('/api/v1/reminders/upcoming')->assertOk()->json('data');
        $this->assertSame(['soon'], array_column($upcoming, 'title'));
    }

    public function test_completing_watering_reminder_waters_plant_and_schedules_next(): void
    {
        $plant = Plant::factory()->for($this->user)->create(['watering_interval_days' => 5]);
        $reminder = Reminder::factory()->create(['user_id' => $this->user->id, 'plant_id' => $plant->id, 'type' => 'watering', 'due_at' => now()]);

        $this->postJson("/api/v1/reminders/{$reminder->id}/complete")->assertOk()->assertJsonPath('data.is_completed', true);

        $this->assertDatabaseHas('care_logs', ['plant_id' => $plant->id, 'type' => 'watering']);
        $this->assertSame(1, Reminder::where('plant_id', $plant->id)->where('type', 'watering')->where('is_completed', false)->count());
    }

    public function test_completing_other_reminder_types_logs_care(): void
    {
        $plant = Plant::factory()->for($this->user)->create();
        $reminder = Reminder::factory()->create(['user_id' => $this->user->id, 'plant_id' => $plant->id, 'type' => 'pruning']);

        $this->postJson("/api/v1/reminders/{$reminder->id}/complete")->assertOk();
        $this->assertDatabaseHas('care_logs', ['plant_id' => $plant->id, 'type' => 'pruning']);
    }

    public function test_user_cannot_complete_update_or_delete_others_reminder(): void
    {
        $theirs = Reminder::factory()->create();

        $this->postJson("/api/v1/reminders/{$theirs->id}/complete")->assertForbidden();
        $this->putJson("/api/v1/reminders/{$theirs->id}", ['title' => 'x'])->assertForbidden();
        $this->deleteJson("/api/v1/reminders/{$theirs->id}")->assertForbidden();
    }

    public function test_update_and_delete_own_reminder(): void
    {
        $r = Reminder::factory()->create(['user_id' => $this->user->id]);

        $this->putJson("/api/v1/reminders/{$r->id}", ['title' => 'Updated'])->assertOk()->assertJsonPath('data.title', 'Updated');
        $this->deleteJson("/api/v1/reminders/{$r->id}")->assertOk();
        $this->assertDatabaseMissing('reminders', ['id' => $r->id]);
    }

    public function test_reminder_validation(): void
    {
        $this->postJson('/api/v1/reminders', ['type' => 'dancing'])->assertStatus(422)->assertJsonValidationErrors(['plant_id', 'type', 'title', 'due_at']);
    }
}
