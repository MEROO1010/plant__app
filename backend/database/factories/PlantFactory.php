<?php

namespace Database\Factories;

use App\Models\Plant;
use App\Models\PlantCategory;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class PlantFactory extends Factory
{
    public function definition(): array
    {
        $watered = now()->subDays(fake()->numberBetween(0, 6));
        $interval = fake()->randomElement([3, 5, 7, 10, 14]);

        return [
            'user_id' => User::factory(),
            'plant_category_id' => PlantCategory::factory(),
            'name' => fake()->randomElement(['Monstera', 'Pothos', 'Snake Plant', 'Fiddle Leaf Fig', 'Aloe']).' '.fake()->numberBetween(1, 99),
            'species' => fake()->randomElement(['Monstera deliciosa', 'Epipremnum aureum', 'Dracaena trifasciata']),
            'description' => fake()->sentence(),
            'location' => fake()->randomElement(['Living room', 'Bedroom', 'Balcony', 'Kitchen']),
            'light_level' => fake()->randomElement(Plant::LIGHT_LEVELS),
            'watering_interval_days' => $interval,
            'fertilizing_interval_days' => 30,
            'last_watered_at' => $watered,
            'next_watering_at' => $watered->copy()->addDays($interval),
            'last_fertilized_at' => now()->subDays(10),
            'next_fertilizing_at' => now()->addDays(20),
            'health_status' => 'healthy',
        ];
    }
}
