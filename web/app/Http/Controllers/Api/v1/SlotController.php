<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Services\Api\v1\AppointmentService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class SlotController extends BaseController
{

    protected $appointmentService;

    // Inject the service via the constructor
    public function __construct(AppointmentService $appointmentService,)
    {
        $this->appointmentService = $appointmentService;
    }
    /**
     * View available Slots.
     */
    public function index(Request $request)
    {
        $available_slots = [];
        $request->validate([
            'appointment_date' => 'required|date|after_or_equal:' . Carbon::tomorrow()->toDateString(),
            'doctor_id' => 'required|exists:doctors,id',
        ]);

        if(!($doctor = Doctor::find($request->doctor_id))){
            $this->errorResponse('The selected doctor id doesnt exist', 404);
        }
        $available_slots = $this->appointmentService->generateAvailableSlots($doctor, $request->appointment_date);
        if (empty($available_slots)) {
            $this->errorResponse('There is no slots available for this day', 404);
        }
        return $this->successResponse('Slots are available',$available_slots);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
