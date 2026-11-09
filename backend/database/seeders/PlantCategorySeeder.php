<?php

namespace Database\Seeders;

use App\Models\PlantCategory;
use Illuminate\Database\Seeder;

class PlantCategorySeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            ['Indoor', 'indoor', 'Easy companions for everyday rooms.', 'chair', '#2F5D3A'],
            ['Succulent', 'succulent', 'Drought-tolerant, loves bright light.', 'spa', '#8A9A5B'],
            ['Tropical', 'tropical', 'Big leaves that enjoy warmth and humidity.', 'park', '#3E7C59'],
            ['Low Light', 'low-light', 'Thrives away from windows.', 'nights_stay', '#5B6C5D'],
            ['Flowering', 'flowering', 'Seasonal blooms and colour.', 'local_florist', '#D9694F'],
        ];
        foreach ($rows as [$name, $slug, $description, $icon, $color]) {
            PlantCategory::updateOrCreate(['slug' => $slug], compact('name', 'description', 'icon', 'color'));
        }
    }
}
