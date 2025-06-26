<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Http\Requests\Api\v1\AppointmentRequest;
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
    // Inject the service via the constructor
    public function __construct(AppointmentService $appointmentService,)
    {
        $this->appointmentService = $appointmentService;
    }

    /**
     * View All Appointments
     */
    public function index()
    {
        if (Auth::user()->role == 'patient') {
            $id = Auth::user()->patient->id;
            $appointments = Appointment::where('patient_id', $id)->orderBy('appointment_date', 'desc')->orderBy('slot', 'asc')->get();
        } elseif (Auth::user()->role == 'doctor') {
            $id = Auth::user()->doctor->id;
            $appointments = Appointment::where('doctor_id', $id)->orderBy('appointment_date', 'desc')->orderBy('slot', 'asc')->get();
        } elseif (Auth::user()->role == 'admin') {
            $appointments = Appointment::all();
        }
        if ($appointments->isEmpty()) {
            return $this->errorResponse('No appointments found', 404);
        }
        //for admin
        $data['appointments'] = $this->appointmentService->formatAppointments($appointments);
        return $this->successResponse('Appointments retrieved successfully', $data, 200);
    }

    /**
     * Create Appointment
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
            $this->errorResponse('The selected doctor id doesnt exist', 404);
        }
        $appointment_date = Carbon::parse($request->appointment_date);
        $available_slots = $this->appointmentService->generateAvailableSlots($doctor, $appointment_date);
        if (empty($available_slots)) {
            $this->errorResponse('There is no slots available for this day,Please choose another day', 404);
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
            'status' => 'booked',
        ]);

        $hourly_rate = $appointment->doctor->hourly_rate;
        $slot_duration = 0.5; //in hours
        $amount = intval($hourly_rate * $slot_duration);

        Payment::create([
            'appointment_id' => $appointment->id,
            'amount' => $amount,
            'status' => 'unpaid',
        ]);
        $data['appointment'] = $this->appointmentService->formatAppointment($appointment);

        return $this->successResponse('Appointment Created Successfully', $data);
    }

    /**
     * View Appointment Information
     */
    public function show(string $id)
    {
        $appointment = Appointment::find($id);
        if (!$this->verify($appointment,'doctor_id') && !$this->verify($appointment,'patient_id')) {
            return $this->errorResponse('Unauthorized access', 403);
        }
        $data['appointment'] = $this->appointmentService->formatAppointment($appointment);
        return $this->successResponse('Appointment information retrieved successfully.',$data);
    }

    /**
     * Update Appointment
     */
    public function update(Request $request, string $id)
    {
        $appointment = Appointment::find($id);
        if (!$this->verify($appointment, 'patient_id')) {
            return $this->errorResponse('Unauthorized access', 403);
        }
        $payment = Payment::where('appointment_id', $appointment->id)->first();
        if ($appointment->status == 'completed') {
            return $this->errorResponse('Cannot update already completed appointment', 403);
        } elseif ($payment->status == 'paid') {
            return $this->errorResponse('Cannot update already booked appointment', 403);
        }

        $doctor = $appointment->doctor;
        $request->validate([
            'appointment_date' => 'nullable|date|after_or_equal:' . Carbon::tomorrow()->toDateString(),
            'slot' => 'required|date_format:H:i',
            'patient_id' => ['nullable', 'exists:patients,id', function ($attribute, $value, $fail) {
                if (Auth::user()->role === 'admin' && empty($value)) {
                    return $this->errorResponse('Please input patient id.');
                }
            }]
        ]);
        $slot = Carbon::parse($request->slot)->format('H:i');
        if ($request->has('appointment_date') && !empty($request->appointment_date)) {
            $appointment_date = Carbon::parse($request->appointment_date);
        } else {
            $appointment_date = $appointment->appointment_date;
        }


        $available_slots = $this->appointmentService->generateAvailableSlots($doctor, $appointment_date);
        if (empty($available_slots)) {
            return $this->errorResponse('There is no slot available for this day,Please choose another day', 404);
        }

        if (!in_array($slot, $available_slots)) {
            return $this->errorResponse('This slot is not available', 404);
        }

        $appointment->update([
            'appointment_date' => $appointment_date,
            'slot' => $slot,
        ]);
        $data['appointment'] = $this->appointmentService->formatAppointment($appointment);
        return $this->successResponse('Appointment updated successfully.', $data);
    }

    /**
     * Delete Appointment
     */
    public function destroy(string $id)
    {
        $appointment = Appointment::find($id);
        if (!$this->verify($appointment, 'patient_id')) {
            return $this->errorResponse('Unauthorized access', 403);
        }
        if ($appointment->status == 'completed' && Auth::user()->role != 'admin') {
            return $this->errorResponse('Cannot delete already completed appointment', 403);
        }
        if ($appointment->delete()) {
            return $this->successResponse('Appointment deleted successfully', null);
        }
    }

    /**
     * Update Appointment Status
     */
    public function updateAppointmentStatus(Request $request, string $id)
    {
        $appointment = Appointment::find($id);
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
}
