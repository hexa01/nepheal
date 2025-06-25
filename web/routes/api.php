<?php

use App\Http\Controllers\Api\v1\DoctorController;
use App\Http\Controllers\Api\v1\AdminController;
use App\Http\Controllers\Api\v1\AppointmentController;
use App\Http\Controllers\Api\v1\PatientController;
use App\Http\Controllers\Api\v1\ScheduleController;
use App\Http\Controllers\Api\v1\SlotController;
use App\Http\Controllers\Api\v1\SpecializationController;
use App\Http\Controllers\Api\v1\UserAuthController;
use App\Http\Controllers\Api\v1\UserController;
use App\Http\Middleware\RoleMiddleware;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');


Route::prefix('v1')->group(function () {

    Route::get('/test', function () {
    return response()->json(['message' => 'API is working']);
});

    Route::post('/login', [UserAuthController::class, 'login'])->name('api.login');
    Route::post('/register', [UserAuthController::class, 'register'])->name('api.register');

    Route::group(['middleware' => "auth:sanctum"], function () {
        Route::post('/logout', [UserAuthController::class, 'logout']);
        Route::get('/specializations', [SpecializationController::class, 'index'])->name('api.specializations.index');
        Route::apiResource('appointments',AppointmentController::class)->names('api.appointments');
        Route::get('/doctors', [DoctorController::class, 'index'])->name('api.doctors.index');

        Route::middleware('role:patient')->group( function () {
            Route::get('/patient-view', [PatientController::class, 'view'])->name('api.patients.view');
        });
        Route::middleware('role:doctor')->group( function () {
            Route::get('/doctor-view', [DoctorController::class, 'view'])->name('api.doctors.view');
            Route::get('/patients-view', [DoctorController::class, 'viewPatients'])->name('api.doctors.patients.view');
        });


        Route::middleware('role:admin')->group( function () {
            Route::post('/specializations', [SpecializationController::class, 'store'])->name('api.specializations.store');
            Route::put('/specializations/{specialization}', [SpecializationController::class, 'update'])->name('api.specializations.update');
            Route::delete('/specializations/{specialization}', [SpecializationController::class, 'destroy'])->name('api.specializations.delete');
            Route::put('/users/reset-password{user}', [UserController::class, 'resetPassword'])->name('api.users.reset.password');
            Route::apiResource('users',UserController::class)->except('update')->names('api.users');
            Route::apiResource('admins',AdminController::class)->only(['index','update'])->names('api.admins');
        });

        Route::middleware('role:admin,doctor')->group( function () {
            Route::put('/doctors/{doctor}', [DoctorController::class, 'update'])->name('api.doctors.update');
            Route::put('/appointment/status/{appointment}', [AppointmentController::class, 'updateAppointmentStatus'])->name('api.appointment.status.update');
            Route::put('/appointment/message/{appointment}', [AppointmentController::class, 'updateDoctorMessage'])->name('api.message.update');
        });

        Route::middleware('role:admin,patient')->group( function () {
            Route::apiResource('patients',PatientController::class)->only(['index','update'])->names('api.patients');
            Route::apiResource('slots',SlotController::class)->only(['index'])->names('api.slots');
        });

        Route::apiResource('/schedules',ScheduleController::class)->only(['index','update'])->names('api.schedules')->middleware('role:doctor');

    });
});
