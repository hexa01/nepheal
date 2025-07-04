<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\v1\RegisterRequest;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserAuthController extends Controller
{
    /**
     * Login
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'data' => $validator->errors()
            ], 422);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid login credentials',
                'data' => null,
            ], 403);
        }

        $token = $user->createToken($user->role)->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'User logged in successfully',
            'data' => [
                'token' => $token,
                'user' => $user,
            ],
        ], 200);
    }

    /**
     * Register
     */
    public function register(RegisterRequest $request)
    {
        if ($request->role === 'doctor' || $request->role === 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Invalid role. Please choose patient as a role.',
                'data' => null
            ], 403);
        }

        $validated = $request->validated();

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'address' => $validated['address'] ?? null,
            'role' => $validated['role'],
            'phone' => $validated['phone'] ?? null,
            'gender' => $validated['gender'],
            'dob' => $validated['dob'] ?? null,
            'password' => Hash::make($validated['password']),
        ]);
               $token = $user->createToken($user->role)->plainTextToken;

        if ($user->role === 'patient') {
            Patient::create([
                'user_id' => $user->id,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'User registered successfully',
            'data' => [
                'token' => $token,
                'user' => $user,  
            ],
        ], 201);
    }

    /**
     * Logout
     */
    public function logout(Request $request)
    {
        if (Auth::user() && $request->user()->tokens()->exists()) {
            $request->user()->tokens()->delete();

            return response()->json([
                'success' => true,
                'message' => 'Logged out successfully',
                'data' => null
            ], 200);
        }

        return response()->json([
            'success' => false,
            'message' => 'You are already logged out, please login first',
            'data' => null
        ], 401);
    }
}
