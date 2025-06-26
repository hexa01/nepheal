<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Http\Requests\Api\v1\UpdateUserRequest;
use App\Models\Patient;
use App\Models\User;
use App\Services\Api\v1\UserService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class PatientController extends BaseController
{
    protected $userService;

    // Inject the service via the constructor
    public function __construct(UserService $userService)
    {
        $this->userService = $userService;
    }

    /**
     * View all patients (admin only).
     */
    public function index()
    {
        if (Auth::user()->role !== 'admin') {
            return $this->errorResponse('Forbidden Access', 403);
        }

        $patients = User::where('role', 'patient')->get();

        if ($patients->isEmpty()) {
            return $this->errorResponse('No patients found', 404);
        }

        $data = $patients->map(function ($patient) {
            return [
                'id' => $patient->patient->id ?? null,
                'user' => [
                    'id'      => $patient->id,
                    'name'    => $patient->name,
                    'email'   => $patient->email,
                    'phone'   => $patient->phone,
                    'address' => $patient->address,
                    'role'    => $patient->role,
                ],
            ];
        });

        return $this->successResponse('Patients retrieved successfully', $data);
    }

    /**
     * Store a newly created patient. (Not implemented)
     */
    public function store(Request $request)
    {
        return $this->errorResponse('Not implemented', 501);
    }

    /**
     * Display a specific patient. (Not implemented)
     */
    public function show(string $id)
    {
        return $this->errorResponse('Not implemented', 501);
    }

    /**
     * Update patient information.
     */
    public function update(UpdateUserRequest $request, string $id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found', 404);
        }

        if ((Auth::user()->id != $id) && Auth::user()->role !== 'admin') {
            return $this->errorResponse('Forbidden Access', 403);
        }

        if ($request->filled('current_password') && Auth::user()->role !== 'admin') {
            if (!Hash::check($request->current_password, $user->password)) {
                return $this->errorResponse('The current password is incorrect.', 400);
            }
        }

        // If password update only
        if ($request->filled('password')) {
            $user->update([
                'password' => Hash::make($request->password),
            ]);
            return $this->successResponse('Password updated successfully.');
        }

        // Update other fields
        $input = $request->only(['name', 'email', 'phone', 'address']);
        $user->update($input);

        $data['patient'] = $this->userService->formatUser($user);

        return $this->successResponse('Information updated successfully!', $data);
    }

    /**
     * Remove the specified patient. (Not implemented)
     */
    public function destroy(string $id)
    {
        return $this->errorResponse('Not implemented', 501);
    }

    /**
     * View current patient's profile.
     */
    public function view()
    {
        $patient = Patient::with('user')->where('user_id', Auth::user()->id)->first();

        if (!$patient) {
            return $this->errorResponse('Patient profile not found', 404);
        }

        $user = User::find(Auth::user()->id);
        $data['patient'] = $this->userService->formatUser($user);

        return $this->successResponse('Your information retrieved successfully', $data);
    }
}
