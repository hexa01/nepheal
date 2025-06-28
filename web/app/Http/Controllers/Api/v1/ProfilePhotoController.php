<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Intervention\Image\ImageManager as Image;

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

// create new image instance (800 x 600)
$resizedImage = Image::imagick()->read($image);
$image = $resizedImage->resizeDown(300, 300); // 800 x 100

            // Store the resized image
            Storage::disk('public')->put('profile_photos/' . $filename, $resizedImage);

            // Update user profile photo
            $user->update(['profile_photo' => $filename]);

            $data = [
                'profile_photo_url' => $user->profile_photo_url,
                'profile_photo' => $user->profile_photo,
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
        ];

        return $this->successResponse('Profile photo retrieved successfully', $data);
    }
}