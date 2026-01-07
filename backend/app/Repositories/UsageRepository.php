<?php

namespace App\Repositories;

use App\Models\UsageLog;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class UsageRepository
{
    public function getRange(Carbon $from, Carbon $to): Collection
    {
        return UsageLog::with('appliance')
            ->whereBetween('date', [$from->toDateString(), $to->toDateString()])
            ->orderBy('date')
            ->get();
    }

    public function getLastDays(Carbon $endDate, int $days = 30): Collection
    {
        $startDate = $endDate->copy()->subDays($days - 1);

        return UsageLog::select('date', DB::raw('SUM(kwh) as total_kwh'))
            ->whereBetween('date', [$startDate->toDateString(), $endDate->toDateString()])
            ->groupBy('date')
            ->orderBy('date')
            ->get();
    }

    public function upsertBulk(Carbon $date, array $items): void
    {
        $now = now();
        $payload = [];

        foreach ($items as $item) {
            $payload[] = [
                'appliance_id' => $item['appliance_id'],
                'date' => $date->toDateString(),
                'kwh' => $item['kwh'],
                'updated_at' => $now,
                'created_at' => $now,
            ];
        }

        UsageLog::upsert(
            $payload,
            uniqueBy: ['appliance_id', 'date'],
            update: ['kwh', 'updated_at']
        );
    }

    public function forDate(Carbon $date): Collection
    {
        return UsageLog::with('appliance')
            ->whereDate('date', $date->toDateString())
            ->get();
    }
}
