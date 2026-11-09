<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('care_logs', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('plant_id')->constrained()->cascadeOnDelete();
            $t->string('type', 20);
            $t->text('notes')->nullable();
            $t->timestamp('performed_at');
            $t->timestamps();

            $t->index(['user_id', 'performed_at']);
            $t->index(['plant_id', 'performed_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('care_logs');
    }
};
