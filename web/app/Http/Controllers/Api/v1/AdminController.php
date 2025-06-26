<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Http\Requests\Api\v1\UpdateUserRequest;
use App\Models\User;
use App\Services\Api\v1\UserService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminController extends BaseController
{
    protected UserService $userService;

    public function __construct(UserService $userService)
    {
        $this->userService = $userService;
    }

    /**
     * Show all admins.
     */
    public function index()
    {
        $admins = User::where('role', 'admin')->get();

        if ($admins->isEmpty()) {
            return $this->errorResponse('Admins not found', 404);
        }

        $data = $this->userService->formatUsers($admins);
        return $this->successResponse('Admins retrieved successfully', $data);
    }

    /**
     * Store a newly created admin.
     */
    public function store(Request $request)
    {
        return $this->errorResponse('Not implemented yet', 501);
    }

    /**
     * Display the specified admin.
     */
    public function show(string $id)
    {
        return $this->errorResponse('Not implemented yet', 501);
    }

    /**
     * Update admin information.
     */
    public function update(UpdateUserRequest $request, string $id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found', 404);
        }

        $input = $request->only(['name', 'email', 'phone', 'address']);

        if ($request->filled('password')) {
            $input['password'] = Hash::make($request->password);
        }

        $user->update($input);

        $data = $this->userService->formatUser($user);
        return $this->successResponse('Admin information updated successfully', $data);
    }

    /**
     * Remove the specified admin.
     */
    public function destroy(string $id)
    {
        return $this->errorResponse('Not implemented yet', 501);
    }
}
