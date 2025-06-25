<?php

namespace App\Http\Requests\Api\v1;

use Carbon\Carbon;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;

class AppointmentRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'doctor_id' => 'required|exists:doctors,id',
            'appointment_date' => 'required|date|after_or_equal:' . Carbon::tomorrow()->toDateString(),
            'slot' => 'required|date_format:H:i',
            'patient_id' => ['nullable', 'exists:patients,id', function ($attribute, $value, $fail) {
                if (Auth::user()->role === 'admin' && empty($value)) {
                    return $fail('Please input patient id.');
                }
            }]
        ];
    }
    /**
     * Get custom error messages for validation.
     *
     * @return array
     */
    public function messages()
    {
        return [
            'doctor_id.required' => 'Doctor is required.',
            'doctor_id.exists' => 'The selected doctor does not exist.',
            'appointment_date.required' => 'Appointment date is required.',
            'appointment_date.date' => 'The appointment date must be a valid date.',
            'appointment_date.after_or_equal' => 'The appointment date must be at least tomorrow.',
            'slot.required' => 'Slot time is required.',
            'slot.date_format' => 'The slot time must be in the format HH:MM.',
            'patient_id.exists' => 'The selected patient does not exist.'
        ];
    }
}
