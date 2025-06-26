<?php

namespace App\Services\Api\v1;

use App\Models\User;
use Illuminate\Support\Collection;

class UserService
{
    /**
     * Format a single user for API response.
     */
    public function formatUser(User $user): array
    {
        return [
            'user_id' => $user->id,
            'name'    => $user->name,
            'email'   => $user->email,
            'phone'   => $user->phone,
            'address' => $user->address,
            'role'    => $user->role,
        ];
    }

    /**
     * Format multiple users.
     */
    public function formatUsers(Collection|array $users): array
    {
        return collect($users)->map(function (User $user) {
            return $this->formatUser($user);
        })->all();
    }
}
