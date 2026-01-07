<?php

namespace Database\Seeders;

use App\Models\Appliance;
use App\Models\UsageLog;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Seeder;

class UsageLogSeeder extends Seeder
{
    public function run(): void
    {
        $appliances = Appliance::all()->keyBy('name');
        if ($appliances->isEmpty()) {
            return;
        }

        $ac = $appliances['Air Conditioner'] ?? null;
        $microwave = $appliances['Microwave'] ?? null;
        $tv = $appliances['LED TV'] ?? null;

        $startDate = Carbon::today()->subDays(29);
        $logs = [];

        for ($i = 0; $i < 30; $i++) {
            $date = $startDate->copy()->addDays($i)->toDateString();
            if ($ac) {
                $logs[] = [
                    'appliance_id' => $ac->id,
                    'date' => $date,
                    'kwh' => 12.0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
            if ($microwave) {
                $logs[] = [
                    'appliance_id' => $microwave->id,
                    'date' => $date,
                    'kwh' => 0.5,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
            if ($tv) {
                $logs[] = [
                    'appliance_id' => $tv->id,
                    'date' => $date,
                    'kwh' => 0.5,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }

        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        UsageLog::truncate();
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');
        UsageLog::insert($logs);
    }
}
