<?php

namespace App\Filament\Resources\AppointmentResource\Pages;

use App\Filament\Resources\AppointmentResource;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\Payment;
use App\Services\AppointmentService;
use Filament\Actions;
use Filament\Actions\CreateAction;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class CreateAppointment extends CreateRecord
{
    protected static string $resource = AppointmentResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }


    protected function getCreatedNotification(): Notification
    {
        $record = $this->record;
        $text = app(AppointmentService::class)->formatAppointmentAsReadableText($record);
        return Notification::make()
            ->success()
            ->icon('heroicon-o-calendar')
            ->title('Appointment Booked!')
            ->body("$text has been successfully booked.");
    }

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        // dd($data);
        if(Auth::user()->role === 'patient'){
            $data['patient_id'] = Auth::user()->patient->id;
        }

        $doctor = Doctor::find($data['doctor_id']);
        $appointment_date = $data['appointment_date'];

        if (!$doctor || !$appointment_date) {
            Notification::make()
            ->title('Invalid Doctor or appointment date')
            ->body('The selected doctor or appointment date is not available.')
            ->warning()
            ->send();
            throw new \Exception('Invalid doctor or appointment date');
        }

        $appointmentService = app(AppointmentService::class);
        $availableSlots = $appointmentService->generateAvailableSlots($doctor, $appointment_date);
        $slot = $data['slot'];
        if (!in_array($slot, $availableSlots)) {
            Notification::make()
            ->title('Slot Already Booked')
            ->body('The selected time slot is already booked. Please choose another time.')
            ->warning()
            ->send();
            throw new \Exception('The selected slot is already booked. Please choose another time.');

        }
//
unset($data['specialization_id']);
return $data;
}

    protected function afterCreate(): void
    {
        $record = $this->record;  // Access the created Appointment model
        $data = $this->form->getState();
        $hourly_rate = $record->doctor->hourly_rate;
        $slot_duration = 0.5; //in hours
        $amount = intval($hourly_rate * $slot_duration);
        Payment::create([
            'appointment_id' => $record->id,
            'amount' => $amount,
            'status' => 'unpaid',
        ]);
    }
}
