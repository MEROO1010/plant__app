<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('plants', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('plant_category_id')->nullable()->constrained('plant_categories')->nullOnDelete();
            $t->string('name');
            $t->string('species')->nullable();
            $t->text('description')->nullable();
            $t->string('image_url')->nullable();
            $t->string('location')->nullable();
            $t->string('light_level', 20)->default('medium'); // low, medium, bright, direct
            $t->unsignedSmallInteger('watering_interval_days')->default(7);
            $t->unsignedSmallInteger('fertilizing_interval_days')->default(30);
            $t->timestamp('last_watered_at')->nullable();
            $t->timestamp('next_watering_at')->nullable();
            $t->timestamp('last_fertilized_at')->nullable();
            $t->timestamp('next_fertilizing_at')->nullable();
            $t->string('health_status', 20)->default('healthy'); // healthy, needs_attention, critical
            $t->text('notes')->nullable();
            $t->timestamps();

            $t->index(['user_id', 'next_watering_at']);
            $t->index(['user_id', 'health_status']);
            $t->index('name');
            $t->index('species');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plants');
    }
};
