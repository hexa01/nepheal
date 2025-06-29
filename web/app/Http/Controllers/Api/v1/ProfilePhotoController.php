<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProfilePhotoController extends BaseController
{
    /**
     * Upload or update profile photo.
     */
    public function upload(Request $request)
    {
        $request->validate([
            'profile_photo' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048', // 2MB max
        ]);

        $user = Auth::user();

        try {
            // Delete old profile photo if exists
            if ($user->profile_photo) {
                Storage::disk('public')->delete('profile_photos/' . $user->profile_photo);
            }

            $image = $request->file('profile_photo');
            
            // Generate unique filename
            $filename = Str::uuid() . '.' . $image->getClientOriginalExtension();
            
            // Create directory if it doesn't exist
            if (!Storage::disk('public')->exists('profile_photos')) {
                Storage::disk('public')->makeDirectory('profile_photos');
            }

            // Store the image file properly
            $path = $image->storeAs('profile_photos', $filename, 'public');
            
            if (!$path) {
                throw new \Exception('Failed to store image file');
            }

            // Update user profile photo
            $user->update(['profile_photo' => $filename]);

            // Refresh user model to get updated data
            $user->refresh();

            $data = [
                'profile_photo_url' => $user->profile_photo_url,
                'profile_photo' => $user->profile_photo,
                'message' => 'Profile photo uploaded successfully',
            ];

            return $this->successResponse('Profile photo uploaded successfully', $data);

        } catch (\Exception $e) {
            return $this->errorResponse('Failed to upload profile photo: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Delete profile photo.
     */
    public function delete()
    {
        $user = Auth::user();

        try {
            if ($user->profile_photo) {
                // Delete file from storage
                Storage::disk('public')->delete('profile_photos/' . $user->profile_photo);
                
                // Remove from database
                $user->update(['profile_photo' => null]);

                return $this->successResponse('Profile photo deleted successfully');
            }

            return $this->errorResponse('No profile photo to delete', 404);

        } catch (\Exception $e) {
            return $this->errorResponse('Failed to delete profile photo: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get profile photo URL.
     */
    public function show($userId = null)
    {
        $user = $userId ? User::find($userId) : Auth::user();

        if (!$user) {
            return $this->errorResponse('User not found', 404);
        }

        $data = [
            'profile_photo_url' => $user->profile_photo_url,
            'profile_photo' => $user->profile_photo,
            'initials' => $user->initials,
            'name' => $user->name,
        ];

        return $this->successResponse('Profile photo retrieved successfully', $data);
    }
}