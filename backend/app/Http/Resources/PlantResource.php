<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PlantResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'plant_category_id' => $this->plant_category_id,
            'category' => new PlantCategoryResource($this->whenLoaded('category')),
            'name' => $this->name,
            'species' => $this->species,
            'description' => $this->description,
            'image_url' => $this->image_url,
            'location' => $this->location,
            'light_level' => $this->light_level,
            'watering_interval_days' => $this->watering_interval_days,
            'fertilizing_interval_days' => $this->fertilizing_interval_days,
            'last_watered_at' => $this->last_watered_at?->toIso8601String(),
            'next_watering_at' => $this->next_watering_at?->toIso8601String(),
            'last_fertilized_at' => $this->last_fertilized_at?->toIso8601String(),
            'next_fertilizing_at' => $this->next_fertilizing_at?->toIso8601String(),
            'needs_watering' => $this->next_watering_at !== null && $this->next_watering_at->lte(now()),
            'health_status' => $this->health_status,
            'notes' => $this->notes,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
