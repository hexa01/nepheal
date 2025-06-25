<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Http\Requests\Api\v1\RegisterRequest;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserAuthController extends BaseController
{
        /**
     * Login
     */
    public function login(Request $request)
    {
        // if(Auth::user()){
        //     $token = $request->user()->currentAccessToken();
        //     return $this->errorResponse('You are already logged in. Your Token:'. $token);
        // }

        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'error' => 'Validation failed',
                'messages' => $validator->errors()
            ], 422);
        }


        $user = User::where('email', $request->email)->first();
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(
                [
                    'message' => 'Invalid login Credentials'
                ],
                403
            );
        }


        $token = $user->createToken($user->role)->plainTextToken;
        return response()->json([
            'message' => 'User logged in Successfully',
            'token' => $token
        ], 200);
    }

        /**
     * Register
     */
    public function register(RegisterRequest $request)
    {
        if ($request->role === 'doctor' || $request->role === 'admin'){
            return $this->errorResponse('Invalid role. Please choose patient as a role.', 403);
        }

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
     * Logout
     */
    public function logout(Request $request)
    {
        // Revoke the token used in the request
        // $request->user()->currentAccessToken()->delete();

        //logout from all devices

        if (Auth::user() && $request->user()->tokens()->exists()) {
            $request->user()->tokens()->delete();
            return response()->json([
                'success' => true,
                'message' => 'Logged out successfully',
            ], 200);
        } else {
            $this->errorResponse('You are already logged out, Please login first', 401);
        }
    }
}
