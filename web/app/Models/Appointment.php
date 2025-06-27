<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Appointment extends Model
{
    protected $fillable = [
        'patient_id',
        'doctor_id',
        'appointment_date',
        'slot',
        'status',
    ];

    public function doctor(){
        return $this->belongsTo(Doctor::class);
    }

    public function patient(){
        return $this->belongsTo(Patient::class);
    }

    public function payment(){
        return $this->hasOne(Payment::class);
    }

    public function message(){
        return $this->hasOne(Message::class);
    }

    /**
     * Get the review for this appointment.
     */
    public function review(){
        return $this->hasOne(Review::class);
    }

    /**
     * Check if this appointment has been reviewed.
     */
    public function hasReview()
    {
        return $this->review()->exists();
    }

    /**
     * Check if this appointment can be reviewed.
     */
    public function canBeReviewed()
    {
        return $this->status === 'completed' && !$this->hasReview();
    }

    /**
     * Scope to get completed appointments without reviews.
     */
    public function scopeCompletedWithoutReview($query)
    {
        return $query->where('status', 'completed')
                     ->whereDoesntHave('review');
    }
}