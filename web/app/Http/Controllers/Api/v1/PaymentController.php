<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Models\Appointment;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class PaymentController extends BaseController
{
    /**
     * Get all payments for authenticated user
     */
    public function index()
    {
        if (Auth::user()->role == 'patient') {
            $patientId = Auth::user()->patient->id;
            $payments = Payment::whereHas('appointment', function($query) use ($patientId) {
                $query->where('patient_id', $patientId);
            })->with(['appointment.doctor.user', 'appointment.patient.user'])->orderBy('created_at', 'desc')->get();
        } elseif (Auth::user()->role == 'doctor') {
            $doctorId = Auth::user()->doctor->id;
            $payments = Payment::whereHas('appointment', function($query) use ($doctorId) {
                $query->where('doctor_id', $doctorId);
            })->with(['appointment.doctor.user', 'appointment.patient.user'])->orderBy('created_at', 'desc')->get();
        } elseif (Auth::user()->role == 'admin') {
            $payments = Payment::with(['appointment.doctor.user', 'appointment.patient.user'])->orderBy('created_at', 'desc')->get();
        } else {
            return $this->errorResponse('Unauthorized access', 403);
        }

        if ($payments->isEmpty()) {
            return $this->errorResponse('No payments found', 404);
        }

        $data['payments'] = $payments->map(function($payment) {
            return [
                'id' => $payment->id,
                'appointment_id' => $payment->appointment_id,
                'pid' => $payment->pid,
                'amount' => $payment->amount,
                'status' => $payment->status,
                'payment_method' => $payment->payment_method,
                'created_at' => $payment->created_at,
                'updated_at' => $payment->updated_at,
            ];
        });

        return $this->successResponse('Payments retrieved successfully', $data, 200);
    }

    /**
     * Get specific payment details
     */
    public function show(string $id)
    {
        $payment = Payment::with(['appointment.doctor.user', 'appointment.patient.user'])->find($id);
        
        if (!$payment) {
            return $this->errorResponse('Payment not found', 404);
        }

        // Check authorization
        if (!$this->verifyPaymentAccess($payment)) {
            return $this->errorResponse('Unauthorized access', 403);
        }

        $data['payment'] = [
            'id' => $payment->id,
            'appointment_id' => $payment->appointment_id,
            'pid' => $payment->pid,
            'amount' => $payment->amount,
            'status' => $payment->status,
            'payment_method' => $payment->payment_method,
            'created_at' => $payment->created_at,
            'updated_at' => $payment->updated_at,
        ];

        return $this->successResponse('Payment details retrieved successfully', $data, 200);
    }

    /**
     * Initiate payment process for an appointment
     */
    public function initiatePayment(Request $request, string $appointmentId)
    {
        $appointment = Appointment::find($appointmentId);
        
        if (!$appointment) {
            return $this->errorResponse('Appointment not found', 404);
        }

        // Check if user can access this appointment
        if (!$this->verify($appointment, 'patient_id')) {
            return $this->errorResponse('Unauthorized access', 403);
        }

        $payment = Payment::where('appointment_id', $appointmentId)->first();
        
        if (!$payment) {
            return $this->errorResponse('Payment record not found', 404);
        }

        if ($payment->status === 'paid') {
            return $this->errorResponse('Payment already completed', 400);
        }

        // Generate unique payment ID for eSewa
        $pid = 'apt_' . $appointmentId . '_' . time();
        
        // Update payment with new PID
        $payment->update([
            'pid' => $pid,
            'payment_method' => 'esewa'
        ]);

        // Prepare eSewa payment data
        $esewaConfig = [
            'pid' => $pid,
            'amount' => $payment->amount,
            'tAmt' => $payment->amount,
            'txAmt' => 0,
            'psc' => 0,
            'pdc' => 0,
            'scd' => env('ESEWA_MERCHANT_CODE', 'EPAYTEST'),
            'su' => env('APP_URL') . '/api/v1/payment/success',
            'fu' => env('APP_URL') . '/api/v1/payment/failure',
        ];

        $data['payment'] = [
            'id' => $payment->id,
            'appointment_id' => $payment->appointment_id,
            'pid' => $payment->pid,
            'amount' => $payment->amount,
            'status' => $payment->status,
            'esewa_config' => $esewaConfig
        ];

        return $this->successResponse('Payment initiated successfully', $data, 200);
    }

    /**
     * Verify payment from eSewa
     */
    public function verifyPayment(Request $request)
    {
        $request->validate([
            'pid' => 'required|string',
            'oid' => 'required|string',
            'amt' => 'required|numeric',
            'refId' => 'required|string',
        ]);

        $payment = Payment::where('pid', $request->pid)->first();
        
        if (!$payment) {
            return $this->errorResponse('Payment record not found', 404);
        }

        // Check if payment amount matches
        if ($payment->amount != $request->amt) {
            return $this->errorResponse('Payment amount mismatch', 400);
        }

        try {
            // Verify with eSewa server
            $verificationResult = $this->verifyWithEsewa($request->all());
            
            if ($verificationResult) {
                // Update payment status
                $payment->update([
                    'status' => 'paid',
                    'payment_method' => 'esewa'
                ]);

                // Update appointment status to booked
                $payment->appointment->update([
                    'status' => 'booked'
                ]);

                $data['payment'] = [
                    'id' => $payment->id,
                    'appointment_id' => $payment->appointment_id,
                    'pid' => $payment->pid,
                    'amount' => $payment->amount,
                    'status' => $payment->status,
                    'appointment_status' => $payment->appointment->status
                ];

                return $this->successResponse('Payment verified and appointment confirmed', $data, 200);
            } else {
                // Mark payment as failed
                $payment->update(['status' => 'failed']);
                return $this->errorResponse('Payment verification failed', 400);
            }
        } catch (\Exception $e) {
            Log::error('Payment verification error: ' . $e->getMessage());
            return $this->errorResponse('Payment verification error', 500);
        }
    }

    /**
     * Handle payment failure
     */
    public function paymentFailure(Request $request)
    {
        $request->validate([
            'pid' => 'required|string',
        ]);

        $payment = Payment::where('pid', $request->pid)->first();
        
        if ($payment && $payment->status !== 'paid') {
            $payment->update(['status' => 'failed']);
        }

        return $this->errorResponse('Payment failed', 400);
    }

    /**
     * Retry failed payment
     */
    public function retryPayment(string $paymentId)
    {
        $payment = Payment::find($paymentId);
        
        if (!$payment) {
            return $this->errorResponse('Payment not found', 404);
        }

        if (!$this->verifyPaymentAccess($payment)) {
            return $this->errorResponse('Unauthorized access', 403);
        }

        if ($payment->status === 'paid') {
            return $this->errorResponse('Payment already completed', 400);
        }

        // Reset payment status to unpaid and generate new PID
        $newPid = 'apt_' . $payment->appointment_id . '_' . time();
        $payment->update([
            'pid' => $newPid,
            'status' => 'unpaid'
        ]);

        // Return payment config for retry
        $esewaConfig = [
            'pid' => $newPid,
            'amount' => $payment->amount,
            'tAmt' => $payment->amount,
            'txAmt' => 0,
            'psc' => 0,
            'pdc' => 0,
            'scd' => env('ESEWA_MERCHANT_CODE', 'EPAYTEST'),
            'su' => env('APP_URL') . '/api/v1/payment/success',
            'fu' => env('APP_URL') . '/api/v1/payment/failure',
        ];

        $data['payment'] = [
            'id' => $payment->id,
            'appointment_id' => $payment->appointment_id,
            'pid' => $payment->pid,
            'amount' => $payment->amount,
            'status' => $payment->status,
            'esewa_config' => $esewaConfig
        ];

        return $this->successResponse('Payment retry initiated', $data, 200);
    }

    /**
     * Private method to verify payment access
     */
    private function verifyPaymentAccess($payment)
    {
        if (Auth::user()->role == 'admin') {
            return true;
        }

        if (Auth::user()->role == 'patient') {
            $patientId = Auth::user()->patient->id;
            return $payment->appointment->patient_id == $patientId;
        }

        if (Auth::user()->role == 'doctor') {
            $doctorId = Auth::user()->doctor->id;
            return $payment->appointment->doctor_id == $doctorId;
        }

        return false;
    }

    /**
     * Private method to verify payment with eSewa
     */
    private function verifyWithEsewa($paymentData)
    {
        // eSewa verification URL
        $verifyUrl = env('ESEWA_VERIFY_URL', 'https://uat.esewa.com.np/epay/transrec');
        
        $postData = [
            'amt' => $paymentData['amt'],
            'rid' => $paymentData['refId'],
            'pid' => $paymentData['pid'],
            'scd' => env('ESEWA_MERCHANT_CODE', 'EPAYTEST')
        ];

        $curl = curl_init();
        curl_setopt_array($curl, [
            CURLOPT_URL => $verifyUrl,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => http_build_query($postData),
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/x-www-form-urlencoded'
            ],
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_TIMEOUT => 30
        ]);

        $response = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        curl_close($curl);

        // eSewa returns "SUCCESS" for successful verification
        return $httpCode == 200 && trim($response) === 'SUCCESS';
    }
}