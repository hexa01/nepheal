<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
        protected $fillable = [
        'appointment_id',
        'pid',
        'amount',
        'status',
        'payment_method',
    ];

    public function appointment(){
        return $this->belongsTo(Appointment::class);
    }
}
