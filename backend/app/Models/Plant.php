<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Plant extends Model
{
    use HasFactory;

    public const HEALTH_STATUSES = ['healthy', 'needs_attention', 'critical'];
    public const LIGHT_LEVELS = ['low', 'medium', 'bright', 'direct'];

    // user_id is deliberately NOT fillable: it is always set from the authenticated user.
    protected $fillable = [
        'plant_category_id', 'name', 'species', 'description', 'image_url', 'location',
        'light_level', 'watering_interval_days', 'fertilizing_interval_days',
        'last_watered_at', 'next_watering_at', 'last_fertilized_at', 'next_fertilizing_at',
        'health_status', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'watering_interval_days' => 'integer',
            'fertilizing_interval_days' => 'integer',
            'last_watered_at' => 'datetime',
            'next_watering_at' => 'datetime',
            'last_fertilized_at' => 'datetime',
            'next_fertilizing_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function category(): BelongsTo { return $this->belongsTo(PlantCategory::class, 'plant_category_id'); }
    public function reminders(): HasMany { return $this->hasMany(Reminder::class); }
    public function careLogs(): HasMany { return $this->hasMany(CareLog::class); }
}
