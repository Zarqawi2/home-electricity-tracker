<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DashboardResource extends JsonResource
{
    public static $wrap = null;

    public function toArray(Request $request): array
    {
        return [
            'summary' => $this['summary'],
            'line_chart' => $this['line_chart'],
            'pie_chart' => $this['pie_chart'],
            // Appliances already shaped as arrays with computed costs; return as-is.
            'appliances' => $this['appliances'],
            'tips' => $this['tips'],
        ];
    }
}
