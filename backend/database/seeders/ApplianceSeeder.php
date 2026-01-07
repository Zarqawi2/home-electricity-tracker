<?php

namespace Database\Seeders;

use App\Models\Appliance;
use App\Models\UsageLog;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class ApplianceSeeder extends Seeder
{
    public function run(): void
    {
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        UsageLog::truncate();
        Appliance::truncate();
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        $appliances = [
            ['id' => (string) Str::uuid(), 'name' => 'Refrigerator', 'category' => 'Kitchen', 'power_watts' => 150, 'daily_use_hours' => 24, 'is_on' => false],
            ['id' => (string) Str::uuid(), 'name' => 'Air Conditioner', 'category' => 'Climate Control', 'power_watts' => 1500, 'daily_use_hours' => 8, 'is_on' => true],
            ['id' => (string) Str::uuid(), 'name' => 'LED TV', 'category' => 'Entertainment', 'power_watts' => 100, 'daily_use_hours' => 5, 'is_on' => true],
            ['id' => (string) Str::uuid(), 'name' => 'Washing Machine', 'category' => 'Laundry', 'power_watts' => 500, 'daily_use_hours' => 1.5, 'is_on' => false],
            ['id' => (string) Str::uuid(), 'name' => 'Water Heater', 'category' => 'Water Heating', 'power_watts' => 3000, 'daily_use_hours' => 2, 'is_on' => false],
            ['id' => (string) Str::uuid(), 'name' => 'Microwave', 'category' => 'Kitchen', 'power_watts' => 1000, 'daily_use_hours' => 0.5, 'is_on' => true],
        ];

        Appliance::insert($appliances);
    }
}
