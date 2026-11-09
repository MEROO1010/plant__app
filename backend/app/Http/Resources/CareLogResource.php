<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CareLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'plant_id' => $this->plant_id,
            'plant' => $this->whenLoaded('plant', fn () => ['id' => $this->plant->id, 'name' => $this->plant->name]),
            'type' => $this->type,
            'notes' => $this->notes,
            'performed_at' => $this->performed_at?->toIso8601String(),
        ];
    }
}
