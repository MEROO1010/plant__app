<?php

namespace App\Services;

use App\Models\CareLog;
use App\Models\Plant;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class PlantService
{
    public function __construct(private ReminderService $reminders) {}

    public function paginate(User $user, array $filters, int $perPage): LengthAwarePaginator
    {
        $query = Plant::query()->with('category')->where('user_id', $user->id)
            ->when($filters['search'] ?? null, function ($q, $s) {
                $q->where(fn ($w) => $w->where('name', 'like', "%{$s}%")->orWhere('species', 'like', "%{$s}%"));
            })
            ->when($filters['category_id'] ?? null, fn ($q, $c) => $q->where('plant_category_id', $c))
            ->when($filters['health_status'] ?? null, fn ($q, $h) => $q->where('health_status', $h));

        match ($filters['sort'] ?? 'next_watering') {
            'name' => $query->orderBy('name'),
            'newest' => $query->orderByDesc('created_at'),
            // Soonest watering first, plants without a schedule last.
            default => $query->orderByRaw('next_watering_at IS NULL')->orderBy('next_watering_at'),
        };

        return $query->paginate($perPage);
    }

    public function create(User $user, array $data, ?UploadedFile $image = null): Plant
    {
        return DB::transaction(function () use ($user, $data, $image) {
            unset($data['image']);
            if ($image) {
                $data['image_url'] = $this->storeImage($image);
            }

            $wateredAt = isset($data['last_watered_at']) ? Carbon::parse($data['last_watered_at']) : now();
            $fertAt = isset($data['last_fertilized_at']) ? Carbon::parse($data['last_fertilized_at']) : now();
            $data['last_watered_at'] = $wateredAt;
            $data['last_fertilized_at'] = $fertAt;
            $data['next_watering_at'] = $wateredAt->copy()->addDays($data['watering_interval_days'] ?? 7);
            $data['next_fertilizing_at'] = $fertAt->copy()->addDays($data['fertilizing_interval_days'] ?? 30);

            $plant = new Plant($data);
            $plant->user_id = $user->id;
            $plant->save();

            $this->reminders->schedule($plant, 'watering', $plant->next_watering_at);
            $this->reminders->schedule($plant, 'fertilizing', $plant->next_fertilizing_at);

            return $plant->load('category');
        });
    }

    public function update(Plant $plant, array $data, ?UploadedFile $image = null): Plant
    {
        return DB::transaction(function () use ($plant, $data, $image) {
            unset($data['image']);
            if ($image) {
                $this->deleteImage($plant->image_url);
                $data['image_url'] = $this->storeImage($image);
            }

            $plant->fill($data);

            // Keep schedules in sync when the interval or last-care date changes.
            if ($plant->isDirty(['watering_interval_days', 'last_watered_at']) && $plant->last_watered_at) {
                $plant->next_watering_at = $plant->last_watered_at->copy()->addDays($plant->watering_interval_days);
            }
            if ($plant->isDirty(['fertilizing_interval_days', 'last_fertilized_at']) && $plant->last_fertilized_at) {
                $plant->next_fertilizing_at = $plant->last_fertilized_at->copy()->addDays($plant->fertilizing_interval_days);
            }
            $plant->save();

            if ($plant->wasChanged(['next_watering_at']) && $plant->next_watering_at) {
                $this->reminders->schedule($plant, 'watering', $plant->next_watering_at);
            }
            if ($plant->wasChanged(['next_fertilizing_at']) && $plant->next_fertilizing_at) {
                $this->reminders->schedule($plant, 'fertilizing', $plant->next_fertilizing_at);
            }

            return $plant->load('category');
        });
    }

    public function delete(Plant $plant): void
    {
        $this->deleteImage($plant->image_url);
        $plant->delete();
    }

    public function water(Plant $plant, ?string $notes = null, ?Carbon $at = null): Plant
    {
        return DB::transaction(function () use ($plant, $notes, $at) {
            $at ??= now();
            $plant->update([
                'last_watered_at' => $at,
                'next_watering_at' => $at->copy()->addDays($plant->watering_interval_days),
            ]);
            $this->log($plant, 'watering', $notes, $at);
            $this->reminders->completePending($plant, 'watering');
            $this->reminders->schedule($plant, 'watering', $plant->next_watering_at);

            return $plant->fresh('category');
        });
    }

    public function fertilize(Plant $plant, ?string $notes = null, ?Carbon $at = null): Plant
    {
        return DB::transaction(function () use ($plant, $notes, $at) {
            $at ??= now();
            $plant->update([
                'last_fertilized_at' => $at,
                'next_fertilizing_at' => $at->copy()->addDays($plant->fertilizing_interval_days),
            ]);
            $this->log($plant, 'fertilizing', $notes, $at);
            $this->reminders->completePending($plant, 'fertilizing');
            $this->reminders->schedule($plant, 'fertilizing', $plant->next_fertilizing_at);

            return $plant->fresh('category');
        });
    }

    public function rotate(Plant $plant, ?string $notes = null): Plant
    {
        $this->log($plant, 'rotating', $notes, now());

        return $plant->fresh('category');
    }

    public function log(Plant $plant, string $type, ?string $notes, Carbon $at): CareLog
    {
        $log = new CareLog(['plant_id' => $plant->id, 'type' => $type, 'notes' => $notes, 'performed_at' => $at]);
        $log->user_id = $plant->user_id;
        $log->save();

        return $log;
    }

    private function storeImage(UploadedFile $file): string
    {
        // Random hashed file name; extension comes from the validated mime type, not user input.
        return Storage::disk('public')->url($file->store('plants', 'public'));
    }

    private function deleteImage(?string $url): void
    {
        if ($url && str_contains($url, '/storage/plants/')) {
            Storage::disk('public')->delete('plants/'.basename($url));
        }
    }
}
