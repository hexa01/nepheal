<?php

namespace Database\Seeders;

use App\Models\Specialization;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class SpecializationSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $specializations = [
            'General Medicine',
            'Cardiology',
            'Neurology', 
            'Orthopedics',
            'Pediatrics',
            'Dermatology',
            'Ophthalmology',
            'ENT',
            'Gynecology',
            'Psychiatry',
            'Radiology',
            'Anesthesiology',
        ];

        foreach ($specializations as $specialization) {
            Specialization::firstOrCreate([
                'name' => $specialization
            ]);
        }
    }
}