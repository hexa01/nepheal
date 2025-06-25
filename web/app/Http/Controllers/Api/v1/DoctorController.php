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
     * Show all doctors
     */
    public function index()
    {
        $doctors = Doctor::with('user', 'specialization')->get();
        if ($doctors->isEmpty()) {
            return $this->errorResponse('No doctors found', 404);
        }
        $data['doctors'] = $doctors->map(function ($doctor) {
            return [
                'id' => $doctor->id,
                'user' => [
                    'name' => $doctor->user->name,
                    'email' => $doctor->user->email,
                    'phone' => $doctor->user->phone,
                    'address' => $doctor->user->address,
                    'role' => $doctor->user->role,
                    'specialization' => $doctor->specialization->name,
                ],
            ];
        });
        return $this->successResponse('Doctors retrieved successfully',$data);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update Doctors Information
     */
    public function update(UpdateUserRequest $request, string $id)
    {
        $user = User::find($id);
        if(!$this->userVerify($user)){
            return $this->errorResponse('Unauthorized Access', 403);
        }

        $doctor = Doctor::where('user_id', $id)->first();
        if (!$doctor) {
            return $this->errorResponse('UnAuthorized Access', 404);
        }

        if ($request->filled('current_password') && Auth::user()->role !== 'admin') {
            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'The current password is incorrect.'
                ], 400);
            }
        }

        // Prepare the data to update
        $input = $request->only(['name', 'email', 'phone', 'address', 'specialization_id']);

        if ($request->filled('password')) {
            $user->update([
                'password' => Hash::make($request->input('password')),
            ]);
            return $this->successResponse('Password updated successfully.', null);

        }
        $user->update($input);
        if ($request->filled('specialization_id') && Auth::user()->role === 'admin') {
            $doctor->update([
                'specialization_id' => $request('specialization_id')
            ]);
        }
        $data['user_id'] = $doctor->user->id;
        $data['doctor'] = [
            'doctor_id' => $doctor->id,
            'name' => $doctor->user->name,
            'email' => $doctor->user->email,
            'phone' => $doctor->user->phone,
            'address' => $doctor->user->address,
            'role' => $doctor->user->role,
            'specialization' => $doctor->specialization->name];

        return response()->json([
            'success' => true,
            'message' => 'Doctor information updated successfully!',
            'data' => $data
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }

        /**
     * View my Profile
     */
    public function view(){
        $doctor = Doctor::with('user')->where('user_id', Auth::user()->id)->first();
        $data['user_id'] = $doctor->user->id;
        $data['doctor'] = [
            'doctor_id' => $doctor->id,
            'name' => $doctor->user->name,
            'email' => $doctor->user->email,
            'phone' => $doctor->user->phone,
            'address' => $doctor->user->address,
            'role' => $doctor->user->role,
            'specialization' => $doctor->specialization->name];
        return $this->successResponse('Your information retrieved successfully', $data);
    }

        /**
     * View my patients
     */
    public function viewPatients()
    {
        $doctor = Auth::user()->doctor;
        $appointments = $doctor->appointments()->with('patient.user')->where('status', 'completed')->get();
        $patients = $appointments->map(function ($appointment) {
            return $appointment->patient->user;
        })->unique('id');
        if($patients->isEmpty()){
            return $this->errorResponse('No patients found.');
        }
        $patientsInfo = $patients->map(function ($user) {
            return [
                'name' => $user->name,
                'address' => $user->address,
                'phone' => $user->phone,
            ];
        });

        return $this->successResponse('Patients information retrieved successfully', $patientsInfo);
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


}
