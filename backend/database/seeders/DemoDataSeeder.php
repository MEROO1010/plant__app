<?php

namespace Database\Seeders;

use App\Models\CareLog;
use App\Models\Plant;
use App\Models\PlantCategory;
use App\Models\Reminder;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * DEMO DATA ONLY — a sample account and plants for local development.
 * Login: demo@plantcare.test / password
 */
class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::updateOrCreate(
            ['email' => 'demo@plantcare.test'],
            ['name' => 'Demo Gardener', 'password' => 'password'],
        );

        if ($user->plants()->exists()) {
            return;
        }

        $cat = fn (string $slug) => PlantCategory::where('slug', $slug)->value('id');

        // name, species, category slug, location, light, water-days, fert-days, last watered (days ago), health
        $plants = [
            ['Monty', 'Monstera deliciosa', 'tropical', 'Living room', 'bright', 7, 30, 8, 'needs_attention'],
            ['Goldie', 'Epipremnum aureum', 'indoor', 'Kitchen shelf', 'medium', 6, 30, 3, 'healthy'],
            ['Spike', 'Dracaena trifasciata', 'low-light', 'Hallway', 'low', 14, 60, 5, 'healthy'],
            ['Aloe Vera', 'Aloe barbadensis', 'succulent', 'Balcony', 'direct', 14, 45, 10, 'healthy'],
            ['Peace', 'Spathiphyllum wallisii', 'flowering', 'Bedroom', 'low', 5, 30, 6, 'critical'],
            ['Fig', 'Ficus lyrata', 'tropical', 'Office corner', 'bright', 8, 30, 2, 'healthy'],
        ];

        foreach ($plants as [$name, $species, $slug, $location, $light, $wDays, $fDays, $agoDays, $health]) {
            $watered = now()->subDays($agoDays);
            $fertilized = now()->subDays(12);

            $plant = new Plant([
                'plant_category_id' => $cat($slug), 'name' => $name, 'species' => $species,
                'description' => 'Demo plant for development.', 'location' => $location, 'light_level' => $light,
                'watering_interval_days' => $wDays, 'fertilizing_interval_days' => $fDays,
                'last_watered_at' => $watered, 'next_watering_at' => $watered->copy()->addDays($wDays),
                'last_fertilized_at' => $fertilized, 'next_fertilizing_at' => $fertilized->copy()->addDays($fDays),
                'health_status' => $health,
            ]);
            $plant->user_id = $user->id;
            $plant->save();

            foreach ([['watering', $plant->next_watering_at, "Water {$name}"], ['fertilizing', $plant->next_fertilizing_at, "Fertilize {$name}"]] as [$type, $due, $title]) {
                $r = new Reminder(['plant_id' => $plant->id, 'type' => $type, 'title' => $title, 'due_at' => $due]);
                $r->user_id = $user->id;
                $r->save();
            }

            // A short care history: a few past waterings and one fertilizing.
            for ($i = 0; $i < 4; $i++) {
                $log = new CareLog(['plant_id' => $plant->id, 'type' => 'watering', 'performed_at' => $watered->copy()->subDays($wDays * $i)]);
                $log->user_id = $user->id;
                $log->save();
            }
            $log = new CareLog(['plant_id' => $plant->id, 'type' => 'fertilizing', 'notes' => 'Diluted liquid fertilizer.', 'performed_at' => $fertilized]);
            $log->user_id = $user->id;
            $log->save();
        }

        // A completed reminder earlier this week so weekly progress isn't empty.
        $first = $user->plants()->first();
        $done = new Reminder(['plant_id' => $first->id, 'type' => 'rotating', 'title' => "Rotate {$first->name}", 'due_at' => now()->startOfWeek()->addHours(9), 'is_completed' => true, 'completed_at' => now()->startOfWeek()->addHours(10)]);
        $done->user_id = $user->id;
        $done->save();
    }
}
