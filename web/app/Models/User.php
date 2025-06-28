<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;


class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'profile_photo',
        'role',
        'address',
        'phone',
        'gender',
        'dob',
        'password',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Add profile_photo_url to the appends array so it's included in JSON responses
     */
    protected $appends = ['profile_photo_url', 'initials'];

    public function patient()
    {
        return $this->hasOne(Patient::class);
    }

    public function doctor()
    {
        return $this->hasOne(Doctor::class);
    }

    public function hasRole($role): bool
    {
        return $this->role === $role;
    }

    /**
     * Get the profile photo URL.
     */
    public function getProfilePhotoUrlAttribute()
    {
        if ($this->profile_photo) {
            // Make sure the URL is correct
            $url = url('storage/profile_photos/' . $this->profile_photo);
            \Log::info('Generated profile photo URL: ' . $url);
            return $url;
        }
        return null;
    }

    /**
     * Get user initials for avatar fallback.
     */
    public function getInitialsAttribute()
    {
        $nameParts = explode(' ', trim($this->name));
        if (count($nameParts) >= 2) {
            return strtoupper(substr($nameParts[0], 0, 1) . substr($nameParts[1], 0, 1));
        }
        return strtoupper(substr($this->name, 0, 2));
    }

    /**
     * Override toArray to ensure profile_photo_url is included
     */
    public function toArray()
    {
        $array = parent::toArray();
        $array['profile_photo_url'] = $this->profile_photo_url;
        $array['initials'] = $this->initials;
        return $array;
    }
}