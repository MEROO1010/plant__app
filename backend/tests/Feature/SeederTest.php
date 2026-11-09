<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_database_seeder_creates_demo_data_and_is_idempotent(): void
    {
        $this->seed(DatabaseSeeder::class);
        $this->seed(DatabaseSeeder::class);

        $user = User::where('email', 'demo@plantcare.test')->firstOrFail();
        $this->assertSame(6, $user->plants()->count());
        $this->assertSame(5, \App\Models\PlantCategory::count());
        $this->assertGreaterThan(0, $user->careLogs()->count());
    }
}
