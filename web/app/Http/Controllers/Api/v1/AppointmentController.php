<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\Payment;
use App\Services\Api\v1\AppointmentService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AppointmentController extends BaseController
{
    protected $appointmentService;

    public function __construct(AppointmentService $appointmentService)
    {
        $this->appointmentService = $appointmentService;
    }

    /**
     * Get appointments with categorization
     */
    public function index(Request $request)
    {
        $status = $request->query('status'); // 'pending', 'booked', 'completed', 'missed'
        
        if (Auth::user()->role === 'patient') {
            $patient = Auth::user()->patient;
            $query = Appointment::with(['doctor.user', 'payment', 'review'])
                ->where('patient_id', $patient->id);
        } elseif (Auth::user()->role === 'doctor') {
            $doctor = Auth::user()->doctor;
            $query = Appointment::with(['patient.user', 'payment', 'review'])
                ->where('doctor_id', $doctor->id);
        } else {
            // Admin can see all
            $query = Appointment::with(['doctor.user', 'patient.user', 'payment', 'review']);
        }

        if ($status) {
            $query->where('status', $status);
        }

        $appointments = $query->orderBy('appointment_date', 'desc')
            ->orderBy('slot', 'desc')
            ->get();

        // Categorize appointments
        $categorized = [
            'pending' => [],
            'booked' => [],
            'completed' => [],
            'missed' => []
        ];

        foreach ($appointments as $appointment) {
            $formatted = $this->appointmentService->formatAppointment($appointment);
            $categorized[$appointment->status][] = $formatted;
        }

        // If specific status requested, return only that category
        if ($status && isset($categorized[$status])) {
            return $this->successResponse("$status appointments retrieved successfully", $categorized[$status]);
        }
        
        // Return all categorized
        $data = [
            'categorized' => $categorized,
            'summary' => [
                'total' => $appointments->count(),
                'pending' => count($categorized['pending']),
                'booked' => count($categorized['booked']),
                'completed' => count($categorized['completed']),
                'missed' => count($categorized['missed'])
            ]
        ];

        return $this->successResponse('Appointments retrieved successfully', $data);
    }

    /**
     * Store New Appointment
     */
    public function store(Request $request)
    {
        $request->validate([
            'doctor_id' => 'required|exists:doctors,id',
            'appointment_date' => 'required|date|after_or_equal:' . Carbon::tomorrow()->toDateString(),
            'slot' => 'required|date_format:H:i',
            'patient_id' => 'nullable|exists:patients,id',
        ]);

        if (!$doctor = Doctor::find($request->doctor_id)) {
            return $this->errorResponse('The selected doctor id doesn\'t exist', 404);
        }

        $appointment_date = Carbon::parse($request->appointment_date);
        $available_slots = $this->appointmentService->generateAvailableSlots($doctor, $appointment_date);
        
        if (empty($available_slots)) {
            return $this->errorResponse('There are no slots available for this day. Please choose another day', 404);
        }

        $slot = Carbon::parse($request->slot)->format('H:i');
        if (!in_array($slot, $available_slots)) {
            return $this->errorResponse('This slot is not available', 404);
        }

        if (Auth::user()->role == 'admin') {
            $patientId = $request->patient_id;
        } else {
            $patientId = (Patient::where('user_id', Auth::id())->first())->id;
        }

        $appointment = Appointment::create([
            'patient_id' => $patientId,
            'doctor_id' => $request->doctor_id,
            'appointment_date' => $appointment_date,
            'slot' => $slot,
            'status' => 'pending', // Default status
        ]);

        $hourly_rate = $appointment->doctor->hourly_rate;
        $slot_duration = 0.5; //in hours
        $amount = intval($hourly_rate * $slot_duration);

        $payment = Payment::create([
            'appointment_id' => $appointment->id,
            'amount' => $amount,
            'status' => 'unpaid',
        ]);

        $data = [
            'appointment' => $this->appointmentService->formatAppointment($appointment),
            'payment' => [
                'id' => $payment->id,
                'amount' => $payment->amount,
                'status' => $payment->status
            ]
        ];

        return $this->successResponse('Appointment Created Successfully', $data);
    }

    /**
     * View Appointment Information
     */
    public function show(string $id)
    {
        $appointment = Appointment::with(['doctor.user', 'patient.user', 'payment'])->find($id);
        
        if (!$appointment) {
            return $this->errorResponse('Appointment not found', 404);
        }

        if (!$this->verify($appointment, 'doctor_id') && !$this->verify($appointment, 'patient_id')) {
            return $this->errorResponse('Unauthorized access', 403);
        }

        $data['appointment'] = $this->appointmentService->formatAppointment($appointment);
        return $this->successResponse('Appointment information retrieved successfully.', $data);
    }

    /**
     * Update Appointment (Reschedule)
     */
    public function update(Request $request, string $id)
    {
        $appointment = Appointment::with('payment')->find($id);
        
        if (!$appointment) {
            return $this->errorResponse('Appointment not found', 404);
        }

        if (!$this->verify($appointment, 'patient_id')) {
            return $this->errorResponse('Unauthorized access', 403);
        }

        $payment = $appointment->payment;
        
        // Check if appointment can be updated
        if ($appointment->status == 'completed') {
            return $this->errorResponse('Cannot update already completed appointment', 403);
        } 
        
        if ($appointment->status == 'booked' || ($payment && $payment->status == 'paid')) {
            return $this->errorResponse('Cannot reschedule paid appointment. Please contact support.', 403);
        }

        if ($appointment->status !== 'pending') {
            return $this->errorResponse('Can only reschedule pending appointments', 403);
        }

        $doctor = $appointment->doctor;
        $request->validate([
            'appointment_date' => 'nullable|date|after_or_equal:' . Carbon::tomorrow()->toDateString(),
            'slot' => 'required|date_format:H:i',
        ]);

        $slot = Carbon::parse($request->slot)->format('H:i');
        
        if ($request->has('appointment_date') && !empty($request->appointment_date)) {
            $appointment_date = Carbon::parse($request->appointment_date);
        } else {
            $appointment_date = $appointment->appointment_date;
        }

        $available_slots = $this->appointmentService->generateAvailableSlots($doctor, $appointment_date);
        if (empty($available_slots)) {
            return $this->errorResponse('There are no slots available for this day. Please choose another day', 404);
        }

        if (!in_array($slot, $available_slots)) {
            return $this->errorResponse('This slot is not available', 404);
        }

        $appointment->update([
            'appointment_date' => $appointment_date,
            'slot' => $slot,
        ]);

        $data['appointment'] = $this->appointmentService->formatAppointment($appointment);
        return $this->successResponse('Appointment rescheduled successfully.', $data);
    }

    /**
     * Delete Appointment (Cancel)
     */
    public function destroy(string $id)
    {
        $appointment = Appointment::with('payment')->find($id);
        
        if (!$appointment) {
            return $this->errorResponse('Appointment not found', 404);
        }

        if (!$this->verify($appointment, 'patient_id')) {
            return $this->errorResponse('Unauthorized access', 403);
        }

        // Check if appointment can be cancelled
        if ($appointment->status == 'completed' && Auth::user()->role != 'admin') {
            return $this->errorResponse('Cannot cancel completed appointment', 403);
        }

        if ($appointment->status == 'booked' || ($appointment->payment && $appointment->payment->status == 'paid')) {
            return $this->errorResponse('Cannot cancel paid appointment. Please contact support for refund.', 403);
        }

        if ($appointment->status !== 'pending') {
            return $this->errorResponse('Can only cancel pending appointments', 403);
        }

        if ($appointment->delete()) {
            return $this->successResponse('Appointment cancelled successfully', null);
        }

        return $this->errorResponse('Failed to cancel appointment', 500);
    }

    /**
     * Update Appointment Status (For doctors)
     */
    public function updateAppointmentStatus(Request $request, string $id)
    {
        $appointment = Appointment::find($id);
        
        if (!$appointment) {
            return $this->errorResponse('Appointment not found', 404);
        }

        if (!$this->verify($appointment, 'doctor_id')) {
            return $this->errorResponse('Unauthorized access', 403);
        }

        $request->validate([
            'status' => 'required|in:completed,missed',
        ], [
            'status.in' => 'The status must be updated to either completed or missed.',
        ]);

        $this->appointmentService->validateAppointmentStatus($appointment, $request);

        $appointment->update([
            'status' => $request->status,
        ]);

        $data['appointment'] = $this->appointmentService->formatAppointment($appointment);
        return $this->successResponse('Appointment status updated successfully.', $data);
    }

    /**
     * Get appointment statistics
     */
    public function getStats()
    {
        if (Auth::user()->role === 'patient') {
            $patient = Auth::user()->patient;
            $appointments = Appointment::where('patient_id', $patient->id);
        } elseif (Auth::user()->role === 'doctor') {
            $doctor = Auth::user()->doctor;
            $appointments = Appointment::where('doctor_id', $doctor->id);
        } else {
            $appointments = Appointment::query();
        }

        $stats = [
            'total' => $appointments->count(),
            'pending' => $appointments->clone()->where('status', 'pending')->count(),
            'booked' => $appointments->clone()->where('status', 'booked')->count(),
            'completed' => $appointments->clone()->where('status', 'completed')->count(),
            'missed' => $appointments->clone()->where('status', 'missed')->count(),
            'upcoming' => $appointments->clone()
                ->whereIn('status', ['pending', 'booked'])
                ->where('appointment_date', '>=', now()->toDateString())
                ->count(),
        ];

        return $this->successResponse('Appointment statistics retrieved successfully', $stats);
    }
}