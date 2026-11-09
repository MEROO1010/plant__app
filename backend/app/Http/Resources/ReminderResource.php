<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReminderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'plant_id' => $this->plant_id,
            'plant' => $this->whenLoaded('plant', fn () => ['id' => $this->plant->id, 'name' => $this->plant->name, 'image_url' => $this->plant->image_url]),
            'type' => $this->type,
            'title' => $this->title,
            'description' => $this->description,
            'due_at' => $this->due_at?->toIso8601String(),
            'completed_at' => $this->completed_at?->toIso8601String(),
            'is_completed' => $this->is_completed,
            'is_overdue' => ! $this->is_completed && $this->due_at->lt(now()),
        ];
    }
}
