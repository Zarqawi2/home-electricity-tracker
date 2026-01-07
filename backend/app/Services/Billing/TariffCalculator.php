<?php

namespace App\Services\Billing;

use Illuminate\Support\Collection;

class TariffCalculator
{
    public function __construct(private readonly TariffTable $tariffTable)
    {
    }

    public function calculate(float $kwh): int
    {
        $remaining = $kwh;
        $lowerBound = 0.0;
        $cost = 0.0;

        /** @var Collection<int, \App\Models\TariffTier> $tiers */
        $tiers = $this->tariffTable->tiers();

        foreach ($tiers as $tier) {
            $upper = $tier->to_kwh ?? INF;
            $band = $upper - $lowerBound;
            $applied = min($remaining, $band);
            if ($applied <= 0) {
                $lowerBound = $upper;
                continue;
            }

            $cost += $applied * $tier->rate_iqd_per_kwh;
            $remaining -= $applied;
            $lowerBound = $upper;

            if ($remaining <= 0) {
                break;
            }
        }

        return (int) round($cost);
    }
}
