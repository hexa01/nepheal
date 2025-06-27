<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Patient extends Model
{
    protected $fillable = [
        'user_id'
    ];

    public function user(){
        return $this->belongsTo(User::class);
    }

    public function appointments(){
        return $this->hasMany(Appointment::class);
    }

    /**
     * Get all reviews written by this patient.
     */
    public function reviews(){
        return $this->hasMany(Review::class);
    }

    /**
     * Get completed appointments that can be reviewed.
     */
    public function completedAppointments(){
        return $this->appointments()->where('status', 'completed');
    }

    /**
     * Get completed appointments that haven't been reviewed yet.
     */
    public function unreviewedCompletedAppointments(){
        return $this->completedAppointments()
            ->whereDoesntHave('review');
    }

    /**
     * Check if patient can review a specific appointment.
     */
    public function canReviewAppointment($appointmentId)
    {
        return $this->appointments()
            ->where('id', $appointmentId)
            ->where('status', 'completed')
            ->whereDoesntHave('review')
            ->exists();
    }
}