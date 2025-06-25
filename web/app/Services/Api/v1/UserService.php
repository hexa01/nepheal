<?php
namespace App\Services\Api\v1;

class UserService
{

    public function formatUser($user)
    {
        return [
            'user_id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'address' => $user->address,
            'role' => $user->role,
        ];
    }
    public function formatUsers($users)
    {
        $formattedUsers = [];

        foreach ($users as $user) {
            $formattedUsers[] = $this->formatUser($user);
        }

        return $formattedUsers;
    }
}
