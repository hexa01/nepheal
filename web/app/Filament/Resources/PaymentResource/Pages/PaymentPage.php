<?php

namespace App\Filament\Resources\PaymentResource\Pages;

use App\Filament\Resources\PaymentResource;
use App\Models\Payment;
use App\Services\AppointmentService;
use Exception;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\Concerns\InteractsWithRecord;
use Filament\Resources\Pages\Page;
use Illuminate\Http\Request;
use Stripe\Charge;
use Stripe\Exception\CardException;
use Stripe\Stripe;

class PaymentPage extends Page
{
    use InteractsWithRecord;
    public $payment;
    public $patient_name;
    protected static string $resource = PaymentResource::class;

    protected static string $view = 'filament.resources.payment-resource.pages.payment-page';
    // Override getRecord() to ensure it always returns an Eloquent model
    public function getRecord(): Payment
    {
        if (!isset($this->record)) {
            throw new \Exception('Record not initialized');
        }

        // Use the record ID passed in the route to retrieve the payment model
        return Payment::find($this->record);
    }

    public function mount($record): void
    {

        $payment = Payment::findOrFail($record);

        if (!$payment) {
            Notification::make()
                ->title('Payment not found')
                ->body('Payment not found!')
                ->danger()
                ->send();
            // Perform the redirection without returning it from mount
            $this->redirectRoute('filament.admin.resources.payments.index');
            return; // Ensure no further processing happens
        }

        if ($payment->payment_status == 'paid') {
            Notification::make()
                ->title('Payment is already done for this appointment.')
                ->body('Payment already done.')
                ->danger()
                ->send();

            // Perform the redirection without returning it from mount
            $this->redirectRoute('filament.admin.resources.payments.index');
            return; // Ensure no further processing happens
        }

        // Set the payment to be used in the view
        $patient_name =  $payment->appointment->patient->user->name;
        $this->payment = $payment;
        $this->patient_name = $patient_name;
    }

    public function createCharge(Request $request, Payment $payment)
    {
        try {

            $appointment = $payment->appointment;
            $usdAmount = $payment->amount/100;
            $text = app(AppointmentService::class)->formatAppointmentAsReadableText($appointment);
            Stripe::setApiKey(env('STRIPE_SECRET'));
            Charge::create([
                "amount" => $usdAmount,
                "currency" => "usd",
                "source" => $request->stripeToken,
                "description" => $text,
            ]);
            $pid = 'apt_' . $appointment->id . '_' . time();
            $payment->update([
                'status' => 'paid',
                'payment_method' => 'stripe',
                'pid' => $pid,
                
            ]);

            $appointment =  $payment->appointment;
            $appointment->status = 'booked';
            $appointment->save();
            Notification::make()
                ->title('Success Payment')
                ->body("Payment success: $text")
                ->success()
                ->icon('heroicon-o-banknotes')
                ->send();
            // Return with success notification
            return redirect()->route('filament.admin.resources.payments.index')->with('success', 'Payment successfully done!');
        } catch (Exception $e) {
            Notification::make()
                ->title('Invalid Response')
                ->body('Received an error response from Stripe.')
                ->danger()
                ->send();
            return redirect()->back();
        }
    }
}
