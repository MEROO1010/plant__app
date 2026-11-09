<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('reminders', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('plant_id')->constrained()->cascadeOnDelete();
            $t->string('type', 20); // watering, fertilizing, rotating, pruning, repotting
            $t->string('title');
            $t->text('description')->nullable();
            $t->timestamp('due_at');
            $t->timestamp('completed_at')->nullable();
            $t->boolean('is_completed')->default(false);
            $t->timestamps();

            $t->index(['user_id', 'is_completed', 'due_at']);
            $t->index(['plant_id', 'type', 'is_completed']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reminders');
    }
};
