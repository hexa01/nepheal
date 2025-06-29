<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use Filament\Notifications\Notification;
use Xentixar\EsewaSdk\Esewa;

class PaymentController extends Controller
{
    public function esewaPay(Payment $payment)
    {
        $transaction_id = 'apt_' . $payment->appointment->id . '_' . time();
        $payment->update(['pid' => $transaction_id]);
        $esewa = new Esewa();
        $esewa->config(
            route('payment.success'), // Success URL
            route('payment.failure'), // Failure URL
            $payment->amount,
            $transaction_id
        );

        return $esewa->init();
    }

    public function esewaPaySuccess()
    {
        $esewa = new Esewa();
        $response = $esewa->decode();

        if ($response) {
            if (isset($response['transaction_uuid'])) {
                $transactionUuid = $response['transaction_uuid'];
                $payment = Payment::where('pid', $transactionUuid)->first();

                if ($payment) {
                    $payment->update([
                        'status' => 'paid',
                        'payment_method' => 'esewa',
                    ]);

                    $payment->appointment->update(['status' => 'booked']);

                    // Filament notification for success
                    Notification::make()
                        ->title('Payment Successful')
                        ->body('The payment has been successfully completed.')
                        ->success()
                        ->send();

                    return redirect()->route('filament.admin.resources.appointments.index');
                }

                Notification::make()
                    ->title('Payment Record Not Found')
                    ->body('The transaction record could not be located.')
                    ->danger()
                    ->send();

                return redirect()->route('filament.admin.resources.payments.index');
            }

            Notification::make()
                ->title('Invalid Response')
                ->body('Received an invalid response from eSewa.')
                ->danger()
                ->send();

            return redirect()->route('filament.admin.resources.payments.index');
        }
    }

    public function esewaPayFailure()
    {
        // Filament notification for failure
        Notification::make()
            ->title('Payment Failed')
            ->body('The payment process has failed. Please try again.')
            ->danger()
            ->send();

        return redirect()->route('filament.admin.resources.payments.index');
    }

}
