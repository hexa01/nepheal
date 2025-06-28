<?php

namespace App\Services\Api\v1;

use App\Models\Appointment;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AppointmentService
{

    public function validateAppointmentStatus(Appointment $appointment, Request $request)
    {

        if (Carbon::parse($appointment->appointment_date)->isFuture()) {
            return response()->json([
                'success' => false,
                'error' => 'You cannot update the appointment status for a future date.',
            ], 401);
        }
    }

    public function generateAvailableSlots($doctor, $appointment_date)
    {
                $available_slots = [];

        $appointment_date = Carbon::parse($appointment_date);
        $appointment_day = $appointment_date->englishDayOfWeek;
        $schedule = $doctor->schedules->where('day', $appointment_day)->first();

        $schedule_status = $schedule->status;
        if (!$schedule || $schedule_status !== 'available') {
            return [];
        }


        $slot_count = $schedule->slot_count;
        $start_time = Carbon::parse($schedule->start_time);

        for ($i = 0; $i < $slot_count; $i++) {
            $available_slots[] = $start_time->format('H:i');
            $start_time->addMinutes(30);
        }
        $booked_slots = Appointment::where('doctor_id', $doctor->id)
        ->whereDate('appointment_date', $appointment_date)
        ->get()

        ->pluck('slot')
        ->map(fn($slot) => Carbon::parse($slot)->format('H:i'))
        ->toArray();
        
        $available_slots = array_filter($available_slots, function ($slot) use ($booked_slots) {
            return !in_array($slot, $booked_slots);
        });

        return $available_slots;
    }


    public function formatAppointment($appointment)
    {
        return [
            'id' => $appointment->id,
            'date' => Carbon::parse($appointment->appointment_date)->format('Y-m-d'),
            'slot' => $appointment->slot,
            'status' => $appointment->status,
            'doctor_id' => $appointment->doctor_id,
            'doctor_name' => $appointment->doctor->user->name,
            'doctor_specialization' => $appointment->doctor->specialization->name,
            'patient_id' => $appointment->patient_id,
            'patient_name' => $appointment->patient->user->name,
            'patient_email' => $appointment->patient->user->email,
        ];
    }
    public function formatAppointments($appointments)
    {
        $formattedAppointments = [];

        foreach ($appointments as $appointment) {
            $formattedAppointments[] = $this->formatAppointment($appointment);
        }

        return $formattedAppointments;
    }
}