<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Requests\Api\v1\UpdateUserRequest;
use App\Models\Patient;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Http\Controllers\Api\v1\BaseController;
use App\Services\Api\v1\UserService;

class PatientController extends BaseController
{

    protected $userService;
    // Inject the service via the constructor
    public function __construct(UserService $userService,)
    {
        $this->userService = $userService;
    }

    /**
     * View all Patients
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
        $data['patients'] = $patients->map(function ($patient) {
            return [
                'id' => $patient->patient->id,
                'user' => [
                    'id' => $patient->id,
                    'name' => $patient->name,
                    'email' => $patient->email,
                    'phone' => $patient->phone,
                    'address' => $patient->address,
                    'role' => $patient->role,
                ],
            ];
        });
        return $this->successResponse('Patients retrieved successfully', $data);
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
     * Update Patient Information
     */
    public function update(UpdateUserRequest $request, string $id)
    {

        if (!($user = User::find($id))) {
            return $this->errorResponse('User not found', 404);
        };
        if ((Auth::user()->id != $id) && Auth::user()->role !== 'admin') {
            return $this->errorResponse('Forbidden Access', 403);
        };

        if ($request->filled('current_password') && Auth::user()->role !== 'admin') {
            if (!Hash::check($request->current_password, $user->password)) {
                return $this->errorResponse('The current password is incorrect.', 400);
            }
        }

        // Prepare the data to update
        $input = $request->only(['name', 'email', 'phone', 'address']);

        // Update the password only if provided
        if ($request->filled('password')) {

            // $input['password'] = Hash::make($request->input('password'));
            $user->update([
                'password' => Hash::make($request->input('password')),
            ]);
            return $this->successResponse('Password updated successfully.', null);
        }

        $user->update($input);

        $data['patient'] = $this->userService->formatUser($user);
        return $this->successResponse('Information updated successfully!', $data);
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
    public function view()
    {
        $patient = Patient::with('user')->where('user_id', Auth::user()->id)->first();
        $user = User::find(Auth::user()->id);
        $data['patient'] = $this->userService->formatUser($user);
        return $this->successResponse('Your information retrieved successfully', $data);
    }
}
