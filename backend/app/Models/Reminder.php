<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Reminder extends Model
{
    use HasFactory;

    public const TYPES = ['watering', 'fertilizing', 'rotating', 'pruning', 'repotting'];

    protected $fillable = ['plant_id', 'type', 'title', 'description', 'due_at', 'completed_at', 'is_completed'];

    protected function casts(): array
    {
        return ['due_at' => 'datetime', 'completed_at' => 'datetime', 'is_completed' => 'boolean'];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function plant(): BelongsTo { return $this->belongsTo(Plant::class); }
}
