<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TariffTier extends Model
{
    use HasFactory;

    protected $fillable = [
        'from_kwh',
        'to_kwh',
        'rate_iqd_per_kwh',
    ];
}
