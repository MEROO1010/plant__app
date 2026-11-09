<?php

namespace App\Http\Requests;

use App\Models\Reminder;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ReminderRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $req = $this->isMethod('POST') ? 'required' : 'sometimes';

        return [
            // The plant must belong to the authenticated user.
            'plant_id' => [$req, 'integer', Rule::exists('plants', 'id')->where('user_id', $this->user()->id)],
            'type' => [$req, Rule::in(Reminder::TYPES)],
            'title' => [$req, 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'due_at' => [$req, 'date'],
        ];
    }
}
