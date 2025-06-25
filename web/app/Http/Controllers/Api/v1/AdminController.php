<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Http\Requests\Api\v1\UpdateUserRequest;
use App\Models\User;
use App\Services\Api\v1\UserService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class AdminController extends BaseController
{
    protected $userService;
    // Inject the service via the constructor
    public function __construct(UserService $userService,)
    {
        $this->userService = $userService;
    }

    /**
     * Show all admins
     */
    public function index()
    {
        $admins = User::where('role', 'admin')->get();
        if ($admins->isEmpty()) {
            return $this->errorResponse('Admins not found', 404);
        }
        $data['admins'] = $this->userService->formatUsers($admins);
        return $this->successResponse('Admins retrieved successfully', $data);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request) {}

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update admins information
     */
    public function update(UpdateUserRequest $request, string $id)
    {

        if (!$user = User::find($id)) {
            return $this->errorResponse('User not found', 404);
        }

        // if ($request->filled('current_password') && Auth::user()->role !== 'admin') {
        //     if (!Hash::check($request->current_password, $user->password)) {
        //         return response()->json([
        //             'success' => false,
        //             'message' => 'The current password is incorrect.'
        //         ], 400);
        //     }
        // }
        // Prepare the data to update
        $input = $request->only(['name', 'email', 'phone', 'address']);
        // Update the password only if provided
        if ($request->filled('password')) {
            $input['password'] = Hash::make($request->input('password')); // Use Hash::make() for consistency
        }

        // Update the user profile with the validated input
        $user->update($input);
        $data['admin'] = $this->userService->formatUser($user);
        return $this->successResponse('Admin information updated successfully', $data);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
