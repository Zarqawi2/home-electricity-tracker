<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ApplianceStoreRequest;
use App\Http\Requests\ApplianceUpdateRequest;
use App\Http\Resources\ApplianceResource;
use App\Repositories\ApplianceRepository;
use App\Services\Billing\TariffCalculator;
use Illuminate\Support\Collection;

class ApplianceController extends Controller
{
    public function __construct(
        private readonly ApplianceRepository $repository,
        private readonly TariffCalculator $tariffCalculator,
    )
    {
    }

    public function index()
    {
        $appliances = $this->repository->all();
        $averageRate = $this->calculateAverageRate($appliances);

        $appliances = $appliances->map(function ($appliance) use ($averageRate) {
            $appliance->monthly_cost_iqd = (int) round($appliance->daily_kwh * 30 * $averageRate);
            return $appliance;
        });

        return ApplianceResource::collection($appliances);
    }

    public function store(ApplianceStoreRequest $request)
    {
        $appliance = $this->repository->create($request->validated());
        $this->attachMonthlyCost($appliance);
        return new ApplianceResource($appliance);
    }

    public function show(string $id)
    {
        $appliance = $this->repository->find($id);
        $this->attachMonthlyCost($appliance);
        return new ApplianceResource($appliance);
    }

    public function update(ApplianceUpdateRequest $request, string $id)
    {
        $appliance = $this->repository->update($id, $request->validated());
        $this->attachMonthlyCost($appliance);
        return new ApplianceResource($appliance);
    }

    public function destroy(string $id)
    {
        $this->repository->delete($id);
        return response()->noContent();
    }

    public function toggle(string $id)
    {
        $appliance = $this->repository->toggle($id);
        $this->attachMonthlyCost($appliance);
        return new ApplianceResource($appliance);
    }

    private function calculateAverageRate(?Collection $appliances = null): float
    {
        $appliances ??= $this->repository->all();
        $totalKwh = $appliances
            ->where('is_on', true)
            ->sum(fn ($a) => $a->daily_kwh) * 30;

        if ($totalKwh <= 0) {
            return 0;
        }

        $totalCost = $this->tariffCalculator->calculate($totalKwh);
        return $totalCost / $totalKwh;
    }

    private function attachMonthlyCost($appliance): void
    {
        $averageRate = $this->calculateAverageRate();
        $appliance->monthly_cost_iqd = (int) round($appliance->daily_kwh * 30 * $averageRate);
    }
}
