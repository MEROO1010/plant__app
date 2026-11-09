<?php

namespace App\Http\Requests;

use App\Models\CareLog;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CareLogRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'plant_id' => ['required', 'integer', Rule::exists('plants', 'id')->where('user_id', $this->user()->id)],
            'type' => ['required', Rule::in(CareLog::TYPES)],
            'notes' => ['nullable', 'string', 'max:2000'],
            'performed_at' => ['nullable', 'date', 'before_or_equal:now'],
        ];
    }
}
