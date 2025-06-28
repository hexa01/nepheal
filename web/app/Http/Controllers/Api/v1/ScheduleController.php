<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Models\Appointment;
use App\Models\Schedule;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ScheduleController extends BaseController
{
    /**
     * Display my schedule (doctor).
     */
    public function index()
    {
        $doctorId = Auth::user()->doctor->id;

        $schedules = Schedule::where('doctor_id', $doctorId)
            ->select('id', 'doctor_id', 'day', 'start_time', 'end_time', 'slots', 'status', 'created_at', 'updated_at')
            ->get()
            ->sortBy(function ($schedule) {
                $days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
                return array_search($schedule->day, $days);
            })
            ->values(); // Reset array keys after sorting

        return $this->successResponse('Your schedules retrieved successfully', $schedules, 200);
    }

    /**
     * Store a newly created resource in storage. (Not implemented)
     */
    public function store(Request $request)
    {
        return $this->errorResponse('Not implemented', 501);
    }

    /**
     * Display the specified resource. (Not implemented)
     */
    public function show(string $id)
    {
        return $this->errorResponse('Not implemented', 501);
    }

    /**
     * Update my Schedule (doctor)
     */
    public function update(Request $request, string $day_name)
    {
        $request->validate([
            'start_time' => 'required|string|date_format:H:i',
            'end_time'   => 'required|string|date_format:H:i|after:start_time',
        ]);

        $day = ucfirst(strtolower($day_name));
        $validDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

        if (!in_array($day, $validDays)) {
            return $this->errorResponse('This is not a valid day', 404);
        }

        $doctor = Auth::user()->doctor;
        $doctorId = $doctor->id;

        // Check if appointments exist on this day in the future
        $appointmentDates = Appointment::where('doctor_id', $doctorId)
            ->whereDate('appointment_date', '>', now())
            ->distinct()
            ->pluck('appointment_date')
            ->toArray();

        $appointmentDays = array_map(function ($date) {
            return Carbon::parse($date)->englishDayOfWeek;
        }, $appointmentDates);

        if (in_array($day, $appointmentDays)) {
            return $this->errorResponse('Appointment exists on this day. You can\'t update the schedule.', 403);
        }

        $schedule = Schedule::where('doctor_id', $doctorId)->where('day', $day)->first();

        if (!$schedule) {
            return $this->errorResponse('Schedule not found', 404);
        }

        $startTime = Carbon::parse($request->start_time);
        $endTime = Carbon::parse($request->end_time);
        $durationMinutes = $startTime->diffInMinutes($endTime);
        $slots = intdiv($durationMinutes, 30);

        $schedule->update([
            'start_time' => $startTime->format('H:i'),
            'end_time'   => $endTime->format('H:i'),
            'slots'      => $slots,
        ]);

        $data = [
            'schedule' => [
                'id'         => $schedule->id,
                'doctor_id'  => $schedule->doctor_id,
                'day'        => $schedule->day,
                'start_time' => $schedule->start_time,
                'end_time'   => $schedule->end_time,
                'slots'      => $schedule->slots,
                'status'     => $schedule->status,
                'created_at' => $schedule->created_at,
                'updated_at' => $schedule->updated_at,
            ]
        ];

        return $this->successResponse('Your schedule updated successfully', $data);
    }

    /**
     * Remove the specified resource from storage. (Not implemented)
     */
    public function destroy(string $id)
    {
        return $this->errorResponse('Not implemented', 501);
    }

    /**
     * Check if doctor has appointments on a specific day
     */
    public function checkAppointments(Request $request)
    {
        $request->validate([
            'day' => 'required|string|in:sunday,monday,tuesday,wednesday,thursday,friday,saturday',
        ]);

        $day = ucfirst(strtolower($request->day));
        $doctorId = Auth::user()->doctor->id;

        // Get all future appointment dates for this doctor
        $appointmentDates = Appointment::where('doctor_id', $doctorId)
            ->whereDate('appointment_date', '>', now())
            ->distinct()
            ->pluck('appointment_date')
            ->toArray();

        // Convert dates to day names
        $appointmentDays = array_map(function ($date) {
            return Carbon::parse($date)->englishDayOfWeek;
        }, $appointmentDates);

        $hasAppointments = in_array($day, $appointmentDays);

        $data = [
            'day' => $day,
            'has_appointments' => $hasAppointments,
            'can_edit' => !$hasAppointments,
        ];

        return $this->successResponse('Appointment status retrieved successfully', $data);
    }

    /**
     * Get all days with appointments for the doctor
     */
    public function getDaysWithAppointments()
    {
        $doctorId = Auth::user()->doctor->id;

        // Get all future appointment dates for this doctor
        $appointmentDates = Appointment::where('doctor_id', $doctorId)
            ->whereDate('appointment_date', '>', now())
            ->distinct()
            ->pluck('appointment_date')
            ->toArray();

        // Convert dates to day names and remove duplicates
        $appointmentDays = array_unique(array_map(function ($date) {
            return Carbon::parse($date)->englishDayOfWeek;
        }, $appointmentDates));

        $daysStatus = [];
        $validDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

        foreach ($validDays as $day) {
            $daysStatus[$day] = [
                'day' => $day,
                'has_appointments' => in_array($day, $appointmentDays),
                'can_edit' => !in_array($day, $appointmentDays),
            ];
        }

        return $this->successResponse('Days with appointments retrieved successfully', $daysStatus);
    }

    /**
     * Toggle schedule status (active/inactive) for a specific day
     */
    public function toggleStatus(Request $request, string $day_name)
    {
        $day = ucfirst(strtolower($day_name));
        $validDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

        if (!in_array($day, $validDays)) {
            return $this->errorResponse('This is not a valid day', 404);
        }

        $doctorId = Auth::user()->doctor->id;

        // Check if appointments exist on this day in the future
        $appointmentDates = Appointment::where('doctor_id', $doctorId)
            ->whereDate('appointment_date', '>', now())
            ->distinct()
            ->pluck('appointment_date')
            ->toArray();

        $appointmentDays = array_map(function ($date) {
            return Carbon::parse($date)->englishDayOfWeek;
        }, $appointmentDates);

        if (in_array($day, $appointmentDays)) {
            return $this->errorResponse('Cannot change status for days with existing appointments.', 403);
        }

        $schedule = Schedule::where('doctor_id', $doctorId)->where('day', $day)->first();

        if (!$schedule) {
            return $this->errorResponse('Schedule not found', 404);
        }

        // Toggle status
        $newStatus = $schedule->status === 'active' ? 'inactive' : 'active';
        $schedule->update(['status' => $newStatus]);

        $data = [
            'schedule' => [
                'id'         => $schedule->id,
                'doctor_id'  => $schedule->doctor_id,
                'day'        => $schedule->day,
                'start_time' => $schedule->start_time,
                'end_time'   => $schedule->end_time,
                'slots'      => $schedule->slots,
                'status'     => $schedule->status,
                'created_at' => $schedule->created_at,
                'updated_at' => $schedule->updated_at,
            ]
        ];

        return $this->successResponse("Schedule status updated to {$newStatus}", $data);
    }
}