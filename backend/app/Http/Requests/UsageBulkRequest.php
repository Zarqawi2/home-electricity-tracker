<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UsageBulkRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'date' => ['required', 'date_format:Y-m-d'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.appliance_id' => ['required', 'exists:appliances,id'],
            'items.*.kwh' => ['required', 'numeric', 'min:0'],
        ];
    }
}
