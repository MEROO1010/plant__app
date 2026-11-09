<?php

namespace App\Http\Requests;

use App\Models\Plant;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Shared rules for creating (required name) and updating (all optional) a plant.
 */
class PlantRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $req = $this->isMethod('POST') ? 'required' : 'sometimes';

        return [
            'name' => [$req, 'string', 'max:255'],
            'plant_category_id' => ['nullable', 'integer', 'exists:plant_categories,id'],
            'species' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:5000'],
            'image_url' => ['nullable', 'url', 'max:2048'],
            // Uploads: restricted to common image types, 2 MB max.
            'image' => ['nullable', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'location' => ['nullable', 'string', 'max:255'],
            'light_level' => ['sometimes', Rule::in(Plant::LIGHT_LEVELS)],
            'watering_interval_days' => ['sometimes', 'integer', 'min:1', 'max:365'],
            'fertilizing_interval_days' => ['sometimes', 'integer', 'min:1', 'max:730'],
            'last_watered_at' => ['nullable', 'date'],
            'last_fertilized_at' => ['nullable', 'date'],
            'health_status' => ['sometimes', Rule::in(Plant::HEALTH_STATUSES)],
            'notes' => ['nullable', 'string', 'max:5000'],
        ];
    }
}
