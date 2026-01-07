<?php

namespace App\Services\Billing;

use App\Models\TariffTier;
use Illuminate\Support\Collection;

class TariffTable
{
    public function tiers(): Collection
    {
        return TariffTier::orderBy('from_kwh')->get();
    }
}
