<?php

namespace App\Http\Controllers\Api\v1;

use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\Message;
use App\Models\Patient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class MessageController extends BaseController
{
    /**
     * Get completed appointments for doctor to send messages
     */
    public function getCompletedAppointments()
    {
        try {
            $user = Auth::user();
            
            if ($user->role !== 'doctor') {
                return $this->errorResponse('Unauthorized access', 403);
            }

            $doctor = Doctor::where('user_id', $user->id)->first();
            
            if (!$doctor) {
                return $this->errorResponse('Doctor profile not found', 404);
            }

            $appointments = Appointment::where('doctor_id', $doctor->id)
                ->where('status', 'completed')
                ->with([
                    'patient.user:id,name,email,phone',
                    'message:id,appointment_id,doctor_message'
                ])
                ->orderBy('appointment_date', 'desc')
                ->get();

            $formattedAppointments = $appointments->map(function ($appointment) {
                return [
                    'id' => $appointment->id,
                    'appointment_date' => $appointment->appointment_date,
                    'slot' => $appointment->slot,
                    'patient' => [
                        'id' => $appointment->patient->id,
                        'name' => $appointment->patient->user->name,
                        'email' => $appointment->patient->user->email,
                        'phone' => $appointment->patient->user->phone,
                    ],
                    'has_message' => $appointment->message ? true : false,
                    'message' => $appointment->message ? [
                        'id' => $appointment->message->id,
                        'doctor_message' => $appointment->message->doctor_message,
                        'created_at' => $appointment->message->created_at,
                        'updated_at' => $appointment->message->updated_at,
                    ] : null,
                ];
            });

            return $this->successResponse(
                'Completed appointments retrieved successfully', 
                $formattedAppointments
            );

        } catch (\Exception $e) {
            return $this->errorResponse('Failed to retrieve appointments: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Send message to patient
     */
    public function sendMessage(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'appointment_id' => 'required|exists:appointments,id',
                'doctor_message' => 'required|string|max:1000',
            ]);

            if ($validator->fails()) {
                return $this->errorResponse('Validation failed', 422, $validator->errors());
            }

            $user = Auth::user();
            
            if ($user->role !== 'doctor') {
                return $this->errorResponse('Unauthorized access', 403);
            }

            $doctor = Doctor::where('user_id', $user->id)->first();
            
            if (!$doctor) {
                return $this->errorResponse('Doctor profile not found', 404);
            }

            $appointment = Appointment::where('id', $request->appointment_id)
                ->where('doctor_id', $doctor->id)
                ->where('status', 'completed')
                ->first();

            if (!$appointment) {
                return $this->errorResponse('Appointment not found or not completed', 404);
            }

            // Check if message already exists
            $existingMessage = Message::where('appointment_id', $request->appointment_id)->first();

            if ($existingMessage) {
                return $this->errorResponse('Message already exists for this appointment', 400);
            }

            $message = Message::create([
                'appointment_id' => $request->appointment_id,
                'doctor_message' => $request->doctor_message,
            ]);

            $message->load('appointment.patient.user:id,name,email');

            return $this->successResponse('Message sent successfully', [
                'message' => [
                    'id' => $message->id,
                    'appointment_id' => $message->appointment_id,
                    'doctor_message' => $message->doctor_message,
                    'created_at' => $message->created_at,
                    'patient_name' => $message->appointment->patient->user->name,
                ]
            ]);

        } catch (\Exception $e) {
            return $this->errorResponse('Failed to send message: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Update existing message
     */
    public function updateMessage(Request $request, $messageId)
    {
        try {
            $validator = Validator::make($request->all(), [
                'doctor_message' => 'required|string|max:1000',
            ]);

            if ($validator->fails()) {
                return $this->errorResponse('Validation failed', 422, $validator->errors());
            }

            $user = Auth::user();
            
            if ($user->role !== 'doctor') {
                return $this->errorResponse('Unauthorized access', 403);
            }

            $doctor = Doctor::where('user_id', $user->id)->first();
            
            if (!$doctor) {
                return $this->errorResponse('Doctor profile not found', 404);
            }

            $message = Message::whereHas('appointment', function ($query) use ($doctor) {
                $query->where('doctor_id', $doctor->id);
            })->find($messageId);

            if (!$message) {
                return $this->errorResponse('Message not found', 404);
            }

            $message->update([
                'doctor_message' => $request->doctor_message,
            ]);

            return $this->successResponse('Message updated successfully', [
                'message' => [
                    'id' => $message->id,
                    'appointment_id' => $message->appointment_id,
                    'doctor_message' => $message->doctor_message,
                    'updated_at' => $message->updated_at,
                ]
            ]);

        } catch (\Exception $e) {
            return $this->errorResponse('Failed to update message: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get messages for patient (patient side)
     */
    public function getPatientMessages()
    {
        try {
            $user = Auth::user();
            
            if ($user->role !== 'patient') {
                return $this->errorResponse('Unauthorized access', 403);
            }

            $patient = Patient::where('user_id', $user->id)->first();
            
            if (!$patient) {
                return $this->errorResponse('Patient profile not found', 404);
            }

            $messages = Message::whereHas('appointment', function ($query) use ($patient) {
                $query->where('patient_id', $patient->id);
            })
            ->with([
                'appointment:id,appointment_date,slot,doctor_id',
                'appointment.doctor.user:id,name',
                'appointment.doctor.specialization:id,name'
            ])
            ->orderBy('created_at', 'desc')
            ->get();

            $formattedMessages = $messages->map(function ($message) {
                return [
                    'id' => $message->id,
                    'doctor_message' => $message->doctor_message,
                    'created_at' => $message->created_at,
                    'appointment' => [
                        'id' => $message->appointment->id,
                        'appointment_date' => $message->appointment->appointment_date,
                        'slot' => $message->appointment->slot,
                        'doctor' => [
                            'name' => $message->appointment->doctor->user->name,
                            'specialization' => $message->appointment->doctor->specialization->name ?? 'General',
                        ]
                    ]
                ];
            });

            return $this->successResponse(
                'Patient messages retrieved successfully', 
                $formattedMessages
            );

        } catch (\Exception $e) {
            return $this->errorResponse('Failed to retrieve messages: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Delete message (doctor only)
     */
    public function deleteMessage($messageId)
    {
        try {
            $user = Auth::user();
            
            if ($user->role !== 'doctor') {
                return $this->errorResponse('Unauthorized access', 403);
            }

            $doctor = Doctor::where('user_id', $user->id)->first();
            
            if (!$doctor) {
                return $this->errorResponse('Doctor profile not found', 404);
            }

            $message = Message::whereHas('appointment', function ($query) use ($doctor) {
                $query->where('doctor_id', $doctor->id);
            })->find($messageId);

            if (!$message) {
                return $this->errorResponse('Message not found', 404);
            }

            $message->delete();

            return $this->successResponse('Message deleted successfully');

        } catch (\Exception $e) {
            return $this->errorResponse('Failed to delete message: ' . $e->getMessage(), 500);
        }
    }
}