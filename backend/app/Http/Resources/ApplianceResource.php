<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ApplianceResource extends JsonResource
{
    public static $wrap = null;

    public function toArray(Request $request): array
    {
        return [
          'id' => $this->id,
          'name' => $this->name,
          'category' => $this->category,
          'power_watts' => $this->power_watts,
          'daily_use_hours' => (float) $this->daily_use_hours,
          'is_on' => (bool) $this->is_on,
          'monthly_cost_iqd' => isset($this->monthly_cost_iqd) ? (int) $this->monthly_cost_iqd : null,
        ];
    }
}
