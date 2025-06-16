<?php

namespace App\Filament\Resources\PaymentResource\Pages;

use App\Filament\Resources\PaymentResource;
use App\Models\Appointment;
use App\Models\User;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;
use Filament\Support\Enums\ActionSize;
use Filament\Tables\Table;
use Filament\Tables;
use Filament\Tables\Actions\Action;
use Filament\Tables\Actions\ActionGroup;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Auth;

class ListPayments extends ListRecords
{
    protected static string $resource = PaymentResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }

    public function table(Table $table): Table
    {
        $user = User::find(Auth::user()->id);
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('appointment.patient.user.name')
                    ->label('Patient Name')
                    ->sortable()
                    ->hidden(fn() => $user->role === 'patient'),
                Tables\Columns\TextColumn::make('appointment.doctor.user.name')
                    ->label('Doctor Name')
                    ->sortable()
                    ->hidden(fn() => $user->role === 'doctor'),
                Tables\Columns\TextColumn::make('appointment.appointment_date')
                    ->label('Appointment Date')
                    ->sortable(),
                Tables\Columns\TextColumn::make('pid')
                    ->toggleable(isToggledHiddenByDefault: true)
                    ->searchable(),


                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'paid' => 'success',
                        'unpaid' => 'danger',
                        default => 'secondary'
                    }),
                Tables\Columns\TextColumn::make('transaction_id')
                    ->toggleable(isToggledHiddenByDefault: true)
                    ->searchable(),
                Tables\Columns\TextColumn::make('payment_method')
                    ->default("-")
                    ->searchable(),
                Tables\Columns\TextColumn::make('amount')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])->defaultSort('status', 'desc')
            ->filters([
                //
            ])
            ->actions([
                ActionGroup::make([
                    Action::make('Pay with eSewa')
                        ->action(function ($record) {
                            return redirect()->route('payment.esewa',$record);
                        })
                        ->icon('heroicon-o-currency-dollar')
                        ->visible(fn ($record) => $record->payment_status !== 'paid')
                        // ->button()
                        ->color('success')
                        ->label('Pay via eSewa')
                        ->requiresConfirmation()
                        ->tooltip('Click to pay via eSewa'),

                    Action::make('Pay with Stripe')
                        ->url(function($record) {

                            $url = url('/admin/payments/stripe', ['payment' => $record]);
                            return $url;
                        })
                        ->label('Pay via Stripe')
                        ->tooltip('Click to pay via Stripe')
                    ->visible(fn($record) => $record->status !== 'paid')
                    ->hidden(fn() => $user->role === 'doctor')
                    ->icon('heroicon-m-credit-card')
                    ->size(ActionSize::Small)
                    ->color('blue')
                    ->button(),
                    ])
                    ->tooltip('Pay')
                    ->label('Pay')
                    ->icon('heroicon-m-credit-card')
                    ->size(ActionSize::Small)
                    ->color('action')
                    ->button()
                    ]);
    }
}
