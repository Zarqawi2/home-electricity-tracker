<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DashboardResource;
use App\Services\DashboardService;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function __construct(private readonly DashboardService $dashboardService)
    {
    }

    public function __invoke()
    {
        $date = request('date') ? Carbon::parse(request('date')) : now();
        $mode = request('mode', 'daily');
        $data = $this->dashboardService->getDashboard($date, $mode);
        return new DashboardResource($data);
    }
}
