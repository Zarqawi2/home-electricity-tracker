<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ApplianceStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'category' => ['required', 'string', 'max:255'],
            'power_watts' => ['required', 'integer', 'min:1'],
            'daily_use_hours' => ['required', 'numeric', 'min:0'],
            'is_on' => ['sometimes', 'boolean'],
        ];
    }
}
