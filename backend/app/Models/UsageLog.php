<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UsageLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'appliance_id',
        'date',
        'kwh',
    ];

    protected $casts = [
        'date' => 'date',
        'kwh' => 'float',
    ];

    public function appliance(): BelongsTo
    {
        return $this->belongsTo(Appliance::class);
    }
}
