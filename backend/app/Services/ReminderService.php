<?php

namespace App\Services;

use App\Models\CareLog;
use App\Models\Plant;
use App\Models\Reminder;
use App\Models\User;
use Carbon\CarbonInterface;
use Illuminate\Pagination\LengthAwarePaginator;

class ReminderService
{
    public function paginate(User $user, array $filters, int $perPage): LengthAwarePaginator
    {
        return Reminder::query()->with('plant:id,name,image_url')
            ->where('user_id', $user->id)
            ->when(($filters['status'] ?? null) === 'completed', fn ($q) => $q->where('is_completed', true))
            ->when(($filters['status'] ?? null) === 'pending', fn ($q) => $q->where('is_completed', false))
            ->when($filters['type'] ?? null, fn ($q, $t) => $q->where('type', $t))
            ->when($filters['plant_id'] ?? null, fn ($q, $p) => $q->where('plant_id', $p))
            ->orderBy('is_completed')->orderBy('due_at')
            ->paginate($perPage);
    }

    /** Pending reminders due today or overdue. */
    public function today(User $user)
    {
        return Reminder::with('plant:id,name,image_url')
            ->where('user_id', $user->id)->where('is_completed', false)
            ->where('due_at', '<=', now()->endOfDay())
            ->orderBy('due_at')->get();
    }

    /** Pending reminders after today, within the next N days. */
    public function upcoming(User $user, int $days = 14)
    {
        return Reminder::with('plant:id,name,image_url')
            ->where('user_id', $user->id)->where('is_completed', false)
            ->where('due_at', '>', now()->endOfDay())
            ->where('due_at', '<=', now()->addDays($days)->endOfDay())
            ->orderBy('due_at')->get();
    }

    public function create(User $user, array $data): Reminder
    {
        $reminder = new Reminder($data);
        $reminder->user_id = $user->id;
        $reminder->save();

        return $reminder->load('plant:id,name,image_url');
    }

    public function update(Reminder $reminder, array $data): Reminder
    {
        $reminder->update($data);

        return $reminder->load('plant:id,name,image_url');
    }

    /** Create or move the single pending reminder of a type for a plant. */
    public function schedule(Plant $plant, string $type, CarbonInterface $dueAt): Reminder
    {
        $title = match ($type) {
            'watering' => "Water {$plant->name}",
            'fertilizing' => "Fertilize {$plant->name}",
            default => ucfirst($type)." {$plant->name}",
        };

        $existing = Reminder::where('plant_id', $plant->id)->where('type', $type)->where('is_completed', false)->first();
        if ($existing) {
            $existing->update(['due_at' => $dueAt]);

            return $existing;
        }

        $reminder = new Reminder(['plant_id' => $plant->id, 'type' => $type, 'title' => $title, 'due_at' => $dueAt]);
        $reminder->user_id = $plant->user_id;
        $reminder->save();

        return $reminder;
    }

    public function completePending(Plant $plant, string $type): void
    {
        Reminder::where('plant_id', $plant->id)->where('type', $type)->where('is_completed', false)
            ->update(['is_completed' => true, 'completed_at' => now()]);
    }

    /**
     * Completing a watering/fertilizing reminder performs the care action
     * (updates the plant, logs it, schedules the next reminder).
     */
    public function complete(Reminder $reminder): Reminder
    {
        if ($reminder->is_completed) {
            return $reminder;
        }

        $plant = $reminder->plant;
        if ($reminder->type === 'watering') {
            app(PlantService::class)->water($plant);
        } elseif ($reminder->type === 'fertilizing') {
            app(PlantService::class)->fertilize($plant);
        } else {
            $reminder->update(['is_completed' => true, 'completed_at' => now()]);
            $log = new CareLog(['plant_id' => $plant->id, 'type' => $reminder->type, 'notes' => $reminder->description, 'performed_at' => now()]);
            $log->user_id = $reminder->user_id;
            $log->save();
        }

        return $reminder->fresh('plant:id,name,image_url');
    }
}
