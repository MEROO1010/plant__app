<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CareLog extends Model
{
    use HasFactory;

    public const TYPES = ['watering', 'fertilizing', 'rotating', 'pruning', 'repotting', 'other'];

    protected $fillable = ['plant_id', 'type', 'notes', 'performed_at'];

    protected function casts(): array
    {
        return ['performed_at' => 'datetime'];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function plant(): BelongsTo { return $this->belongsTo(Plant::class); }
}
