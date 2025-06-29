<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Models\Review;
use App\Models\Appointment;
use App\Models\Doctor;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class ReviewController extends BaseController
{
    /**
     * Get reviews for a specific doctor.
     */
    public function index(Request $request)
    {
        $request->validate([
            'doctor_id' => 'required|exists:doctors,id',
            'page' => 'nullable|integer|min:1',
            'per_page' => 'nullable|integer|min:1|max:50',
        ]);

        $perPage = $request->get('per_page', 10);

        $reviews = Review::with(['patient.user'])
            ->forDoctor($request->doctor_id)
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        $formattedReviews = $reviews->getCollection()->map(function ($review) {
            return [
                'id' => $review->id,
                'rating' => $review->rating,
                'comment' => $review->comment,
                'created_at' => $review->created_at->format('Y-m-d H:i:s'),
                'patient_name' => $review->patient->user->name ?? 'Anonymous',
                'profile_photo_url' => $review->patient->user->profile_photo_url,
                'profile_photo' => $review->patient->user->profile_photo,
                'patient_initials' => $this->getPatientInitials($review->patient->user->name ?? 'A'),
            ];
        });

        return $this->successResponse('Reviews retrieved successfully', [
            'reviews' => $formattedReviews,
            'pagination' => [
                'current_page' => $reviews->currentPage(),
                'total_pages' => $reviews->lastPage(),
                'total_reviews' => $reviews->total(),
                'per_page' => $reviews->perPage(),
            ]
        ]);
    }

    /**
     * Get doctor rating statistics.
     */
    public function getDoctorStats($doctorId)
    {
        $doctor = Doctor::find($doctorId);

        if (!$doctor) {
            return $this->errorResponse('Doctor not found', 404);
        }

        $totalReviews = $doctor->reviews()->count();
        $averageRating = $doctor->reviews()->avg('rating') ?: 0;
        $ratingBreakdown = $doctor->getReviewsCountByRating();

        // Fill missing ratings with 0
        for ($i = 1; $i <= 5; $i++) {
            if (!isset($ratingBreakdown[$i])) {
                $ratingBreakdown[$i] = 0;
            }
        }
        ksort($ratingBreakdown);

        return $this->successResponse('Doctor rating statistics retrieved successfully', [
            'total_reviews' => $totalReviews,
            'average_rating' => round($averageRating, 1),
            'rating_breakdown' => $ratingBreakdown,
        ]);
    }

    /**
     * Create a new review.
     */
    public function store(Request $request)
    {
        $request->validate([
            'appointment_id' => 'required|exists:appointments,id',
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $appointment = Appointment::with(['doctor', 'patient'])->find($request->appointment_id);

        // Verify appointment belongs to authenticated patient
        if ($appointment->patient->user_id !== Auth::id()) {
            return $this->errorResponse('Unauthorized to review this appointment', 403);
        }

        // Check if appointment is completed
        if ($appointment->status !== 'completed') {
            return $this->errorResponse('Can only review completed appointments', 400);
        }

        // Check if already reviewed
        if ($appointment->hasReview()) {
            return $this->errorResponse('This appointment has already been reviewed', 400);
        }

        $review = Review::create([
            'patient_id' => $appointment->patient_id,
            'doctor_id' => $appointment->doctor_id,
            'appointment_id' => $appointment->id,
            'rating' => $request->rating,
            'comment' => $request->comment,
        ]);

        $review->load(['patient.user', 'doctor.user']);

        return $this->successResponse('Review created successfully', [
            'review' => [
                'id' => $review->id,
                'rating' => $review->rating,
                'comment' => $review->comment,
                'created_at' => $review->created_at->format('Y-m-d H:i:s'),
                'doctor_name' => $review->doctor->user->name,
                'patient_name' => $review->patient->user->name,
            ]
        ], 201);
    }

    /**
     * Get patient's reviews.
     */
    public function getPatientReviews()
    {
        $patient = Auth::user()->patient;

        if (!$patient) {
            return $this->errorResponse('Patient profile not found', 404);
        }

        $reviews = Review::with(['doctor.user', 'appointment'])
            ->byPatient($patient->id)
            ->orderBy('created_at', 'desc')
            ->get();

        $formattedReviews = $reviews->map(function ($review) {
            return [
                'id' => $review->id,
                'appointment_id' => $review->appointment_id, // ← THIS WAS MISSING!
                'rating' => $review->rating,
                'comment' => $review->comment,
                'created_at' => $review->created_at->format('Y-m-d H:i:s'),
                'doctor_name' => $review->doctor->user->name,
                'profile_photo_url' => $review->doctor->user->profile_photo_url,
                'profile_photo' => $review->doctor->user->profile_photo,
                'appointment_date' => $review->appointment->appointment_date,
            ];
        });

        return $this->successResponse('Patient reviews retrieved successfully', [
            'reviews' => $formattedReviews
        ]);
    }

    /**
     * Get appointments that can be reviewed by the patient.
     */
    public function getReviewableAppointments()
    {
        $patient = Auth::user()->patient;

        if (!$patient) {
            return $this->errorResponse('Patient profile not found', 404);
        }

        $appointments = $patient->unreviewedCompletedAppointments()
            ->with(['doctor.user', 'doctor.specialization'])
            ->orderBy('appointment_date', 'desc')
            ->get();

        $formattedAppointments = $appointments->map(function ($appointment) {
            return [
                'id' => $appointment->id,
                'appointment_date' => $appointment->appointment_date,
                'slot' => $appointment->slot,
                'doctor' => [
                    'id' => $appointment->doctor->id,
                    'name' => $appointment->doctor->user->name,
                    'profile_photo_url' => $appointment->doctor->user->profile_photo_url,
                    'profile_photo' => $appointment->doctor->user->profile_photo,
                    'specialization' => $appointment->doctor->specialization->name ?? 'General',
                ],
            ];
        });

        return $this->successResponse('Reviewable appointments retrieved successfully', [
            'appointments' => $formattedAppointments
        ]);
    }

    /**
     * Update a review.
     */
    public function update(Request $request, $reviewId)
    {
        $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $review = Review::with(['patient.user'])->find($reviewId);

        if (!$review) {
            return $this->errorResponse('Review not found', 404);
        }

        // Verify review belongs to authenticated patient
        if ($review->patient->user_id !== Auth::id()) {
            return $this->errorResponse('Unauthorized to update this review', 403);
        }

        $review->update([
            'rating' => $request->rating,
            'comment' => $request->comment,
        ]);

        return $this->successResponse('Review updated successfully', [
            'review' => [
                'id' => $review->id,
                'rating' => $review->rating,
                'comment' => $review->comment,
                'updated_at' => $review->updated_at->format('Y-m-d H:i:s'),
            ]
        ]);
    }

    /**
     * Delete a review.
     */
    public function destroy($reviewId)
    {
        $review = Review::with(['patient.user'])->find($reviewId);

        if (!$review) {
            return $this->errorResponse('Review not found', 404);
        }

        // Verify review belongs to authenticated patient or user is admin
        if ($review->patient->user_id !== Auth::id() && Auth::user()->role !== 'admin') {
            return $this->errorResponse('Unauthorized to delete this review', 403);
        }

        $review->delete();

        return $this->successResponse('Review deleted successfully');
    }

    /**
     * Get patient initials for display.
     */
    private function getPatientInitials($name)
    {
        $nameParts = explode(' ', trim($name));
        if (count($nameParts) >= 2) {
            return strtoupper(substr($nameParts[0], 0, 1) . substr($nameParts[1], 0, 1));
        }
        return strtoupper(substr($name, 0, 2));
    }
}
