<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UsageBulkRequest;
use App\Repositories\UsageRepository;
use Carbon\Carbon;

class UsageController extends Controller
{
    public function __construct(private readonly UsageRepository $usageRepository)
    {
    }

    public function index()
    {
        $from = request('from') ? Carbon::parse(request('from')) : now()->subDays(29);
        $to = request('to') ? Carbon::parse(request('to')) : now();

        $logs = $this->usageRepository->getRange($from, $to)->map(function ($log) {
            return [
                'id' => $log->id,
                'appliance_id' => $log->appliance_id,
                'appliance_name' => $log->appliance->name ?? null,
                'date' => $log->date->toDateString(),
                'kwh' => (float) $log->kwh,
            ];
        });

        return ['data' => $logs];
    }

    public function store(UsageBulkRequest $request)
    {
        $date = Carbon::parse($request->validated('date'));
        $items = $request->validated('items');
        $this->usageRepository->upsertBulk($date, $items);

        return response()->json(['status' => 'ok']);
    }
}
