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
                    Action::make('Pay')
                    ->visible(fn($record) => $record->status !== 'paid')
                    ->size(ActionSize::Small)
                    ->button(),
            ]);
    }
}
