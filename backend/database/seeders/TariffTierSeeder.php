<?php

namespace Database\Seeders;

use App\Models\TariffTier;
use Illuminate\Database\Seeder;

class TariffTierSeeder extends Seeder
{
    public function run(): void
    {
        $tiers = [
            ['from_kwh' => 1, 'to_kwh' => 400, 'rate_iqd_per_kwh' => 72],
            ['from_kwh' => 401, 'to_kwh' => 800, 'rate_iqd_per_kwh' => 108],
            ['from_kwh' => 801, 'to_kwh' => 1200, 'rate_iqd_per_kwh' => 175],
            ['from_kwh' => 1201, 'to_kwh' => 1600, 'rate_iqd_per_kwh' => 265],
            ['from_kwh' => 1601, 'to_kwh' => null, 'rate_iqd_per_kwh' => 350],
        ];

        TariffTier::truncate();
        TariffTier::insert($tiers);
    }
}
