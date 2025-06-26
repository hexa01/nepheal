<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\Patient;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class BaseController extends Controller
{
    public function successResponse($message, $data=null, $code = 200)
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $code);
    }
    public function errorResponse($message, $code = 400)
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'data' => null,
        ], $code);
    }

    public function userVerify($model, $ownerColumn = 'id')
    {
        if (!$model) {
            return false;
        }
        if (Auth::user()->role == 'admin') {
            return true;
        }
        return $model->$ownerColumn == Auth::user()->id;
    }

    public function adminVerify(){
        return Auth::user()->role == 'admin';
    }

    public function verify($model, $ownerColumn = 'patient_id')
    {
        if (!$model) {
            return false;
        }

        // If the user is an admin, they are authorized to access any appointment
        if (Auth::user()->role == 'admin') {
            return true;
        }

        // If the authenticated user is a doctor, check if they are the correct doctor
        if (Auth::user()->role == 'doctor') {
            $doctor = Doctor::where('user_id', Auth::user()->id)->first();
            return $model->$ownerColumn == $doctor->id;
        }

        // If the authenticated user is a patient, check if they are the correct patient
        if (Auth::user()->role === 'patient') {
            $patient = Patient::where('user_id', Auth::user()->id)->first();
            if ($model->$ownerColumn == $patient->id) {
                return true;
            }
        }
        return false;
    }
}
