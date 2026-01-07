<?php

namespace App\Services;

use App\Repositories\ApplianceRepository;
use App\Repositories\UsageRepository;
use App\Services\Billing\TariffCalculator;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class DashboardService
{
    /**
     * Small deterministic variations so charts are not flat while still reflecting
     * the base consumption derived from active appliances.
     */
    private array $dailyVariation = [
        0.96, 1.04, 0.98, 1.05, 1.02, 0.97, 1.01, 0.99, 1.06, 1.03,
        0.95, 1.08, 1.02, 0.97, 1.04, 1.00, 0.98, 1.06, 1.01, 0.99,
        1.03, 0.96, 1.07, 0.95, 1.02, 1.05, 1.00, 0.97, 1.03, 1.00,
    ];

    private array $monthlyVariation = [
        0.92, 1.05, 1.01, 0.97, 1.08, 0.99,
        1.02, 1.04, 0.96, 1.10, 0.98, 1.03,
    ];

    public function __construct(
        private readonly ApplianceRepository $applianceRepository,
        private readonly UsageRepository $usageRepository,
        private readonly TariffCalculator $tariffCalculator,
    ) {
    }

    public function getDashboard(Carbon $date, string $mode = 'daily'): array
    {
        $appliances = $this->applianceRepository->all();
        $activeAppliances = $appliances->where('is_on', true);
        $baseDailyKwh = $activeAppliances->sum(fn ($a) => $a->daily_kwh);

        // Build a daily series to drive summary values.
        [$dailyPoints, $dailyToday, $dailyAverage] = $this->buildDailySeries(
            $date,
            $baseDailyKwh
        );
        $monthlyEstimateKwh = $dailyAverage * 30;

        // Select the line chart mode requested by the client.
        $monthlyChart = $this->buildMonthlyChart($date, $baseDailyKwh);
        $lineChart = $mode === 'monthly'
            ? $monthlyChart
            : ['mode' => 'daily', 'points' => $dailyPoints];

        $monthlyCost = $this->tariffCalculator->calculate($monthlyEstimateKwh);

        $applianceData = $appliances->map(function ($appliance) {
            $monthlyKwh = $appliance->daily_kwh * 30;
            // Compute per-appliance cost based on its own monthly kWh using the tariff calculator,
            // so costs remain stable regardless of other appliances or on/off toggles.
            $monthlyCostIqd = $this->tariffCalculator->calculate($monthlyKwh);

            return [
                'id' => $appliance->id,
                'name' => $appliance->name,
                'category' => $appliance->category,
                'power_watts' => $appliance->power_watts,
                'daily_use_hours' => $appliance->daily_use_hours,
                'is_on' => $appliance->is_on,
                'monthly_cost_iqd' => $monthlyCostIqd,
                'monthly_kwh' => $monthlyKwh,
            ];
        })->values();

        $pieChart = $this->buildPieChart($activeAppliances, $baseDailyKwh);

        // Changes versus previous point to avoid hardcoded numbers.
        $prevDaily = $dailyPoints[count($dailyPoints) - 2]['y'] ?? $dailyToday;
        $dailyChange = $prevDaily > 0
            ? (($dailyToday - $prevDaily) / $prevDaily) * 100
            : 0.0;

        $lastMonthly = $monthlyChart['points'][count($monthlyChart['points']) - 1]['y'] ?? $monthlyEstimateKwh;
        $prevMonthly = $monthlyChart['points'][count($monthlyChart['points']) - 2]['y'] ?? $lastMonthly;
        $costChange = $prevMonthly > 0
            ? (($lastMonthly - $prevMonthly) / $prevMonthly) * 100
            : 0.0;

        return [
            'summary' => [
                'daily_kwh' => round($dailyToday, 2),
                'monthly_estimate_kwh' => round($monthlyEstimateKwh, 0),
                'monthly_cost_iqd' => $monthlyCost,
                'daily_change_pct' => round($dailyChange, 1),
                'cost_change_pct' => round($costChange, 1),
            ],
            'line_chart' => $lineChart,
            'pie_chart' => $pieChart,
            'appliances' => $applianceData,
            'tips' => $this->tips(),
        ];
    }

    private function buildDailySeries(Carbon $date, float $baseDailyKwh): array
    {
        $points = [];
        $startDate = $date->copy()->subDays(29);
        $sum = 0.0;

        for ($d = 0; $d < 30; $d++) {
            $current = $startDate->copy()->addDays($d);
            $key = $current->toDateString();
            $variation = $this->dailyVariation[$d % count($this->dailyVariation)];
            $value = max(0, $baseDailyKwh * $variation);
            $sum += $value;
            $points[] = [
                'x' => $key,
                'y' => round($value, 2),
            ];
        }

        $todayValue = $points[count($points) - 1]['y'] ?? 0.0;
        $average = $sum / max(1, count($points));

        return [$points, $todayValue, $average];
    }

    private function buildMonthlyChart(Carbon $date, float $baseDailyKwh): array
    {
        $points = [];
        $current = $date->copy()->startOfMonth()->subMonths(11);

        for ($i = 0; $i < 12; $i++) {
            $month = $current->copy()->addMonths($i);
            $variation = $this->monthlyVariation[$i % count($this->monthlyVariation)];
            $value = max(0, $baseDailyKwh * 30 * $variation);
            $points[] = [
                'x' => $month->format('Y-m'),
                'y' => round($value, 2),
            ];
        }

        return [
            'mode' => 'monthly',
            'points' => $points,
        ];
    }

    private function buildPieChart(Collection $activeAppliances, float $dailyKwh): array
    {
        $total = $dailyKwh > 0 ? $dailyKwh : 1;

        return $activeAppliances
            ->map(function ($appliance) use ($total) {
                return [
                    'appliance_id' => $appliance->id,
                    'name' => $appliance->name,
                    'pct' => round(($appliance->daily_kwh / $total) * 100, 0),
                ];
            })
            ->values()
            ->all();
    }

    private function tips(): array
    {
        return [
            'Turn off appliances when not in use to reduce standby power consumption',
            'Use LED bulbs which consume 75% less energy than incandescent bulbs',
            'Set your thermostat 2-3 degrees lower in winter and higher in summer',
            'Use energy-efficient appliances with high Energy Star ratings',
            'Regular maintenance of AC units can improve efficiency by up to 15%',
        ];
    }
}
