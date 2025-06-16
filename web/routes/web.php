<?php

use App\Filament\Resources\PaymentResource\Pages\PaymentPage;
use App\Http\Controllers\PaymentController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Route::middleware(['auth','verified'])->group(function(){
//     Route::get('/payment/{payment}/pay', [PaymentController::class, 'esewaPay'])->name('payment.esewa');
//     Route::match(['get', 'post'],'/payment/success', [PaymentController::class, 'esewaPaySuccess'])->name('payment.success');
//     Route::get('/payment/failure', [PaymentController::class, 'esewaPayFailure'])->name('payment.failure');
// });


Route::middleware('role:patient,admin')->group( function () {
        Route::get('/payment/{payment}/pay', [PaymentController::class, 'esewaPay'])->name('payment.esewa');
    Route::match(['get', 'post'],'/payment/success', [PaymentController::class, 'esewaPaySuccess'])->name('payment.success');
    Route::get('/payment/failure', [PaymentController::class, 'esewaPayFailure'])->name('payment.failure');
Route::post('filament/admin/payments/stripe/create-charge/{payment}', [PaymentPage::class, 'createCharge'])->name('stripe.create-charge');
});

