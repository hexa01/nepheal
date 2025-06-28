<?php

namespace App\Http\Requests\Api\v1;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class UpdateUserRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // return Auth::check() && (Auth::user()->id == $this->route('id') || Auth::user()->role == 'admin');
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules()
    {
        $userId = $this->route('id') ?? $this->route('user') ?? $this->route('patient') ?? $this->route('doctor');
        
        $rules = [
            'name' => 'nullable|string|max:255',
            'email' => [
                'nullable', 
                'string', 
                'email', 
                'max:255', 
                Rule::unique('users')->ignore($userId) // ✅ FIX: Ignore current user's email
            ],
            'phone' => 'nullable|string|max:30',
            'address' => 'nullable|string|max:255',
            'gender' => 'nullable|string|in:male,female', // ✅ ADD: Gender validation
            'bio' => 'nullable|string|max:500', // ✅ ADD: Bio validation for doctors
            'current_password' => 'nullable|string|min:8',
            'password' => 'nullable|string|min:8|confirmed',
        ];

        if ($this->filled('password') && Auth::user()->role !== 'admin') {
            $rules['password'] = 'required|string|min:8|confirmed';
        }

        if ($this->filled('specialization_id')) {
            $rules['specialization_id'] = 'nullable|exists:specializations,id';
        }

        return $rules;
    }

    /**
     * Configure the error messages for the request.
     *
     * @return array
     */
    public function messages()
    {
        return [
            'current_password.required' => 'Current password is required to change your password.',
            'password.min' => 'Password must be at least 8 characters.',
            'password.confirmed' => 'Password confirmation does not match.',
            'specialization_id.required' => 'Specialization is required for doctors.',
            'specialization_id.exists' => 'The selected specialization is invalid.',
            'email.unique' => 'The email address is already taken by another user.',
            'bio.max' => 'Bio must not exceed 500 characters.', // ✅ ADD: Bio error message
            'gender.in' => 'Gender must be either male or female.', // ✅ ADD: Gender error message
        ];
    }
}