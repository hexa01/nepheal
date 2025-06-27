<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Doctor extends Model
{
    protected $fillable = [
        'user_id',
        'specialization_id',
        'hourly_rate',
        'bio',
    ];

    public function user(){
        return $this->belongsTo(User::class);
    }

    public function specialization(){
        return $this->belongsTo(Specialization::class);
    }

    public function appointments(){
        return $this->hasMany(Appointment::class);
    }

    public function schedules(){
        return $this->hasMany(Schedule::class);
    }

    /**
     * Get all reviews for this doctor.
     */
    public function reviews(){
        return $this->hasMany(Review::class);
    }

    /**
     * Get the average rating for this doctor.
     */
    public function getAverageRatingAttribute()
    {
        return $this->reviews()->avg('rating') ?: 0;
    }

    /**
     * Get the total number of reviews for this doctor.
     */
    public function getTotalReviewsAttribute()
    {
        return $this->reviews()->count();
    }

    /**
     * Get reviews count by rating (1-5 stars).
     */
    public function getReviewsCountByRating()
    {
        return $this->reviews()
            ->selectRaw('rating, COUNT(*) as count')
            ->groupBy('rating')
            ->pluck('count', 'rating')
            ->toArray();
    }

    /**
     * Check if doctor has any reviews.
     */
    public function hasReviews()
    {
        return $this->reviews()->exists();
    }
}