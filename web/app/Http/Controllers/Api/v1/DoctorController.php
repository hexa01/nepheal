<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Http\Requests\Api\v1\UpdateUserRequest;
use App\Models\Doctor;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class DoctorController extends BaseController
{
    /**
     * Show all doctors.
     */
    public function index()
    {
        $doctors = Doctor::with('user', 'specialization')->get();

        if ($doctors->isEmpty()) {
            return $this->errorResponse('No doctors found', 404);
        }

        $data = $doctors->map(function ($doctor) {
            return [
                'id' => $doctor->id,
                'user' => [
                    'name'           => $doctor->user->name,
                    'email'          => $doctor->user->email,
                    'phone'          => $doctor->user->phone,
                    'address'        => $doctor->user->address,
                    'role'           => $doctor->user->role,
                    'specialization' => $doctor->specialization->name,
                ],
            ];
        });

        return $this->successResponse('Doctors retrieved successfully', $data);
    }

    /**
     * Store a new doctor. (Not implemented yet)
     */
    public function store(Request $request)
    {
        return $this->errorResponse('Not implemented yet', 501);
    }

    /**
     * Display the specified doctor. (Not implemented yet)
     */
public function show(string $id)
{
    $doctor = Doctor::with(['user', 'specialization'])->find($id);
    
    if (!$doctor) {
        return $this->errorResponse('Doctor not found', 404);
    }
    
    return $this->successResponse('Doctor retrieved successfully', [
        'id' => $doctor->id,
        'user' => [
            'name' => $doctor->user->name,
            'email' => $doctor->user->email,
            'phone' => $doctor->user->phone,
            'address' => $doctor->user->address,
            'role' => $doctor->user->role,
            'specialization' => $doctor->specialization->name,
        ],
        'bio' => $doctor->bio,
        'hourly_rate' => $doctor->hourly_rate,
    ]);
}

    /**
     * Update doctor's information.
     */
    public function update(UpdateUserRequest $request, string $id)
    {
        $user = User::find($id);

        if (!$this->userVerify($user)) {
            return $this->errorResponse('Unauthorized Access', 403);
        }

        $doctor = Doctor::where('user_id', $id)->first();

        if (!$doctor) {
            return $this->errorResponse('Doctor not found', 404);
        }

        if ($request->filled('current_password') && Auth::user()->role !== 'admin') {
            if (!Hash::check($request->current_password, $user->password)) {
                return $this->errorResponse('The current password is incorrect.', 400);
            }
        }

        // If only password update
        if ($request->filled('password')) {
            $user->update([
                'password' => Hash::make($request->password),
            ]);
            return $this->successResponse('Password updated successfully.');
        }

        // General info update
        $input = $request->only(['name', 'email', 'phone', 'address']);
        $user->update($input);

        // Admin can update specialization
        if ($request->filled('specialization_id') && Auth::user()->role === 'admin') {
            $doctor->update([
                'specialization_id' => $request->input('specialization_id'),
            ]);
        }

        $data = [
            'user_id' => $user->id,
            'doctor' => [
                'doctor_id'      => $doctor->id,
                'name'           => $user->name,
                'email'          => $user->email,
                'phone'          => $user->phone,
                'address'        => $user->address,
                'role'           => $user->role,
                'specialization' => $doctor->specialization->name,
            ],
        ];

        return $this->successResponse('Doctor information updated successfully!', $data);
    }

    /**
     * Remove the specified doctor. (Not implemented yet)
     */
    public function destroy(string $id)
    {
        return $this->errorResponse('Not implemented yet', 501);
    }

    /**
     * View current doctor's profile.
     */
    public function view()
    {
        $doctor = Doctor::with(['user', 'specialization'])->where('user_id', Auth::id())->first();

        if (!$doctor) {
            return $this->errorResponse('Doctor not found', 404);
        }

        $data = [
            'user_id' => $doctor->user->id,
            'doctor'  => [
                'doctor_id'      => $doctor->id,
                'name'           => $doctor->user->name,
                'email'          => $doctor->user->email,
                'phone'          => $doctor->user->phone,
                'address'        => $doctor->user->address,
                'role'           => $doctor->user->role,
                'specialization' => $doctor->specialization->name,
            ],
        ];

        return $this->successResponse('Your information retrieved successfully', $data);
    }

    /**
     * View patients that the doctor has seen (completed appointments).
     */
    public function viewPatients()
    {
        $doctor = Auth::user()->doctor;

        if (!$doctor) {
            return $this->errorResponse('Doctor profile not found.', 404);
        }

        $appointments = $doctor->appointments()
            ->with('patient.user')
            ->where('status', 'completed')
            ->get();

        $patients = $appointments
            ->map(fn($appointment) => $appointment->patient->user)
            ->unique('id');

        if ($patients->isEmpty()) {
            return $this->errorResponse('No patients found.');
        }

        $data = $patients->map(fn($user) => [
            'name'    => $user->name,
            'address' => $user->address,
            'phone'   => $user->phone,
        ])->values();

        return $this->successResponse('Patients information retrieved successfully', $data);
    }
    
}


// public function search(Request $request)
// {
//     $query = $request->get('query');

//     $doctors = Doctor::with(['user', 'speciality', 'appointmentSlots'])
//         ->whereHas('user', function ($q) use ($query) {
//             $q->where('f_name', 'like', "%$query%")
//               ->orWhere('l_name', 'like', "%$query%");
//         })
//         ->get();

//     return response()->json(['doctors' => $doctors]);
// }