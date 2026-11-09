<?php

namespace Database\Factories;

use App\Models\Plant;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ReminderFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'plant_id' => fn (array $attrs) => Plant::factory()->create(['user_id' => $attrs['user_id']])->id,
            'type' => 'watering',
            'title' => 'Water plant',
            'description' => null,
            'due_at' => now()->addDay(),
            'is_completed' => false,
        ];
    }
}
