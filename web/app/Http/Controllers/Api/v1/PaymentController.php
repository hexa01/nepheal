<?php

namespace App\Http\Controllers\Api\v1;

use App\Models\Payment;
use App\Models\Appointment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Xentixar\EsewaSdk\Esewa;

class PaymentController extends BaseController
{
    /**
     * Get all payments for authenticated user
     */
    public function index()
    {
        if (Auth::user()->role === 'patient') {
            $patient = Auth::user()->patient;
            $payments = Payment::with(['appointment.doctor.user'])
                ->whereHas('appointment', function ($query) use ($patient) {
                    $query->where('patient_id', $patient->id);
                })
                ->orderBy('created_at', 'desc')
                ->get();
        } else {
            return $this->errorResponse('Unauthorized access', 403);
        }

        $data = $payments->map(function ($payment) {
            return [
                'id' => $payment->id,
                'appointment_id' => $payment->appointment_id,
                'amount' => $payment->amount,
                'status' => $payment->status,
                'payment_method' => $payment->payment_method,
                'created_at' => $payment->created_at,
                'updated_at' => $payment->updated_at,
                'appointment' => [
                    'id' => $payment->appointment->id,
                    'date' => $payment->appointment->appointment_date,
                    'slot' => $payment->appointment->slot,
                    'status' => $payment->appointment->status,
                    'doctor' => [
                        'name' => $payment->appointment->doctor->user->name,
                        'specialization' => $payment->appointment->doctor->specialization,
                    ]
                ]
            ];
        });

        return $this->successResponse('Payments retrieved successfully', $data);
    }

    /**
     * Get specific payment details
     */
    public function show($id)
    {
        $payment = Payment::with(['appointment.doctor.user', 'appointment.patient.user'])->find($id);
        
        if (!$payment) {
            return $this->errorResponse('Payment not found', 404);
        }

        // Check authorization
        if (Auth::user()->role === 'patient' && Auth::user()->patient->id !== $payment->appointment->patient_id) {
            return $this->errorResponse('Unauthorized access', 403);
        }

        $data = [
            'id' => $payment->id,
            'appointment_id' => $payment->appointment_id,
            'amount' => $payment->amount,
            'status' => $payment->status,
            'payment_method' => $payment->payment_method,
            'pid' => $payment->pid,
            'created_at' => $payment->created_at,
            'updated_at' => $payment->updated_at,
            'appointment' => [
                'id' => $payment->appointment->id,
                'date' => $payment->appointment->appointment_date,
                'slot' => $payment->appointment->slot,
                'status' => $payment->appointment->status,
                'doctor' => [
                    'name' => $payment->appointment->doctor->user->name,
                    'specialization' => $payment->appointment->doctor->specialization,
                ]
            ]
        ];

        return $this->successResponse('Payment details retrieved successfully', $data);
    }

    /**
     * Initiate payment for an appointment
     */
    public function initiatePayment(Request $request, $appointmentId)
    {
        $request->validate([
            'payment_method' => 'required|string|in:esewa,khalti,card',
        ]);

        $appointment = Appointment::with('payment')->find($appointmentId);
        
        if (!$appointment) {
            return $this->errorResponse('Appointment not found', 404);
        }

        // Check authorization
        if (Auth::user()->role === 'patient' && Auth::user()->patient->id !== $appointment->patient_id) {
            return $this->errorResponse('Unauthorized access', 403);
        }

        $payment = $appointment->payment;
        
        if (!$payment) {
            return $this->errorResponse('Payment record not found', 404);
        }

        if ($payment->status === 'paid') {
            return $this->errorResponse('Payment already completed', 400);
        }

        // For now, only eSewa is supported
        if ($request->payment_method !== 'esewa') {
            return $this->errorResponse('Payment method coming soon', 400);
        }

        $data = [
            'payment_id' => $payment->id,
            'amount' => $payment->amount,
            'appointment_id' => $appointment->id,
            'payment_method' => $request->payment_method
        ];

        return $this->successResponse('Payment initiation data retrieved', $data);
    }

    /**
     * Initiate eSewa payment and return HTML form to load in WebView.
     */
    public function esewaInitiate(Request $request)
    {
        $request->validate([
            'payment_id' => 'required|exists:payments,id',
        ]);

        $payment = Payment::with('appointment')->findOrFail($request->payment_id);

        // Ensure the logged-in user owns the appointment (patient role)
        if (Auth::user()->role !== 'patient' || Auth::user()->patient->id !== $payment->appointment->patient_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($payment->status === 'paid') {
            return response()->json(['message' => 'Payment already completed'], 400);
        }

        $transactionId = 'apt_' . $payment->appointment->id . '_' . time();
        $payment->update(['pid' => $transactionId]);

        // Initialize Esewa form
        $esewa = new Esewa();
        $esewa->config(
            route('api.v1.esewa.success'),
            route('api.v1.esewa.failure'),
            $payment->amount,
            $transactionId
        );

        // Capture and return the rendered HTML form
        ob_start();
        $esewa->init(false); // false for RC server
        $html = ob_get_clean();

        return response($html, 200)->header('Content-Type', 'text/html');
    }

    /**
     * eSewa Success Callback
     */
    public function esewaSuccess(Request $request)
    {
        $esewa = new Esewa();
        $response = $esewa->decode();

        if ($response && isset($response['transaction_uuid'])) {
            $payment = Payment::where('pid', $response['transaction_uuid'])->first();

            if ($payment) {
                $payment->update([
                    'status' => 'paid',
                    'payment_method' => 'esewa',
                ]);

                $payment->appointment->update(['status' => 'booked']);

                return response()->json([
                    'success' => true,
                    'message' => 'Payment successful',
                    'payment_id' => $payment->id,
                    'appointment_id' => $payment->appointment_id,
                ]);
            }

            return response()->json(['success' => false, 'message' => 'Payment record not found'], 404);
        }

        return response()->json(['success' => false, 'message' => 'Invalid eSewa response'], 400);
    }

    /**
     * eSewa Failure Callback
     */
    public function esewaFailure()
    {
        return response()->json([
            'success' => false,
            'message' => 'Payment failed or cancelled',
        ], 400);
    }
}