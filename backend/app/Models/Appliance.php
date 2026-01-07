<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Appliance extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'name',
        'category',
        'power_watts',
        'daily_use_hours',
        'is_on',
    ];

    protected $casts = [
        'is_on' => 'boolean',
        'daily_use_hours' => 'float',
    ];

    public function usageLogs(): HasMany
    {
        return $this->hasMany(UsageLog::class);
    }

    public function getDailyKwhAttribute(): float
    {
        return ($this->power_watts / 1000) * $this->daily_use_hours;
    }
}
