<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Http\Requests\Api\v1\RegisterRequest;
use App\Http\Requests\Api\v1\UpdateUserRequest;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\Schedule;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class UserController extends BaseController
{
    /**
     * View all Doctors and Patients
     */
    public function index()
    {

        $users = User::query()->with('doctor','patient')->get();
        if($users->isEmpty()){
            return response()->json(
                [
                    'success'=>false,
                    'message'=>'No users found',
                ],200
            );
        }

        $data['patients'] = Patient::with('user') // Select only specific user fields
        ->get()
        ->map(function ($patient) {
            return [
                'user_id' => $patient->user->id,
                'user' => [
                    'patient_id' => $patient->id,
                    'name' => $patient->user->name,
                    'email' => $patient->user->email,
                    'phone' => $patient->user->phone,
                    'address' => $patient->user->address,
                    'role' => $patient->user->role
                ],
            ];
        });


    $data['doctors'] = Doctor::with('user','specialization')->get()
        ->map(function ($doctor) {
            return [
                'user_id' => $doctor->user->id,
                'user' => [
                    'doctor_id' => $doctor->id,
                    'name' => $doctor->user->name,
                    'email' => $doctor->user->email,
                    'phone' => $doctor->user->phone,
                    'address' => $doctor->user->address,
                    'role' => $doctor->user->role,
                    'specialization' => $doctor->specialization->name,
                ],
            ];
        });

        return response()->json(
            [
                'message'=>'Users Fetched Successfully',
                'users'=>$data,
            ],200
        );

    }

    /**
     * Create new User.
     */
    public function store(RegisterRequest $request)
    {
        $validated = $request->validated();
        // $input['password'] = bcrypt($input['password']);
        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'address' => $validated['address'],
            'role' => $validated['role'],
            'phone' => $validated['phone'],
            'password' => Hash::make($validated['password']),
        ]);
        if ($user->role == 'patient') {
            Patient::create([
                'user_id' => $user->id,
            ]);
        } elseif ($user->role == 'doctor') {
            $specialization_id = NULL;
            if ($request->has('specialization_id')) {
                $specialization_id = $request->specialization_id;
            }
            $doctor = Doctor::create([
                'user_id' => $user->id,
                'specialization_id'  => $specialization_id,
            ]);

            $days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
            foreach ($days as $day) {
                Schedule::create([
                    'doctor_id' => $doctor->id,
                    'day' => $day,
                    'start_time' => '10:00',
                    'end_time' => '17:00',
                    'slots' => 14,
                ]);
            }

        }
        // $success['token'] = $user->createToken('doc-book')->plainTextToken;

        return response()->json([
            'success' => true,
            // 'result' => $success,
            'message' => 'User Registered Successfully',
            'data' => $user,
        ], 201);
    }

    /**
     * View User.
     */
    public function show(string $id)
    {
        try {
            if(!$user = User::find($id)){
                return $this->errorResponse("There is no user with such id.", 404);
            }
            $user_data = [
                'user_id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone' => $user->phone,
                'address' => $user->address,
            ];
            if ($user->role === 'doctor') {
                $doctor = Doctor::where('user_id', $user->id)->with('specialization')->first();
                if ($doctor) {
                    $user_data['doctor_id'] = $doctor->id ?? 'Not Available';
                    $user_data['specialization'] = $doctor->specialization->name ?? 'Not Available';
                }
            }
            if($user->role === 'patient'){
                $user_data['patient_id'] = $user->patient->id ?? 'Not Available';
            }

            return $this->successResponse( 'User details',$user_data);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {

            return response()->json([
                'status' => false,
                'message' => 'No user found'
            ], 404);
        }
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Delete User.
     */
    public function destroy(string $id)
    {
        if(!$user = User::find($id)){
            return response()->json(
                [
                    'success'=>false,
                    'message'=>'User not found',
                ],200
            );
        };
        $user->delete();
        return response()->json(
            [
                'success'=>true,
                'message'=>'User Deleted Successfully',
            ],200
        );
    }

        /**
     * Reset User Password
     */
    public function resetPassword(Request $request, string $id)
    {


        if(!$user = User::find($id)){
            return $this->errorResponse('User not found', 404);
        }
        $request->validate([
            'password' => 'nullable|string|min:8|confirmed',
        ]);
        if ($request->filled('password')) {
            $input['password'] = Hash::make($request->input('password'));
        }
        $data['user'] = [
            'id' => $user->id,
            'name' =>$user->name,
            'role' => $user->role,
        ];
        return $this->successResponse('Password reset successsfully',$data);

    }

    // Add this method to UserController.php
public function changePassword(Request $request)
{
    $request->validate([
        'current_password' => 'required|string',
        'password' => 'required|string|min:8|confirmed',
    ]);

    $user = Auth::user();

    // Verify current password
    if (!Hash::check($request->current_password, $user->password)) {
        return $this->errorResponse('The current password is incorrect.', 400);
    }

    // Update password
    $user->update([
        'password' => Hash::make($request->password),
    ]);

    return $this->successResponse('Password updated successfully.');
}

}
