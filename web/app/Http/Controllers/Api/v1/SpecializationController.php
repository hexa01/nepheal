<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Models\Specialization;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SpecializationController extends BaseController
{

    //body ma dekhako xaina docs ma validation arko use

    /**
     * View all Specializations.
     */
    public function index()
    {
        $specializations = Specialization::all();
        if ($specializations->isEmpty()) {
            return $this->errorResponse('No specializations found',404);
        }

        $data['specialization'] = $specializations->map(function ($specialization) {
                return [
                    'id' => $specialization->id,
                    'name' => $specialization->name,
                ];
            });

        return $this->successResponse('Specializations retrieved successfully', $data['specialization']);
    }

    /**
     * Create new Specialization.
     */
    public function store(Request $request)
    {

        $request->validate([
            'name' => [
                'required',
                'string',
                function ($attribute, $value, $fail) {
                    // Format the name as UC first
                    $formattedName = ucfirst(strtolower($value));

                    // Check if the name already exists in the database, case-insensitively
                    $existingSpecialization = \App\Models\Specialization::whereRaw('LOWER(name) = ?', [strtolower($formattedName)])->first();

                    if ($existingSpecialization) {
                        $fail($attribute.' is already taken.');
                    }
                },
            ],
        ]);

        $specialization_name = ucfirst(strtolower($request->name));
        $specialization = Specialization::create([
            'name' => $specialization_name,
        ]);
        $data['specialization'] = [
            'specialization_id' => $specialization->id,
            'specialization_name' => $specialization->name,
        ];
        return $this->successResponse('Specializations created successfully', $data, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update Specialization.
     */
    public function update(Request $request, string $specialization_name)
    {
        $previous_name = ucfirst(strtolower($specialization_name));
        $specialization = Specialization::where('name', $previous_name)->first();
        if (!$specialization) {
            return $this->errorResponse('Specialization not found', 404);
        }

        $request->validate([
            'name' => [
                'required',
                'string',
                function ($attribute, $value, $fail) {
                    // Format the name as UC first
                    $formattedName = ucfirst(strtolower($value));

                    // Check if the name already exists in the database, case-insensitively
                    $existingSpecialization = \App\Models\Specialization::whereRaw('LOWER(name) = ?', [strtolower($formattedName)])->first();

                    if ($existingSpecialization) {
                        $fail($attribute.' is already taken.');
                    }
                },
            ],
        ]);

        $specialization_name = ucfirst(strtolower($request->name));
        $specialization->update([
            'name' => $specialization_name,
        ]);
        $data['specialization'] = [
            'specialization_id' => $specialization->id,
            'specialization_name' => $specialization->name,
        ];

        return $this->successResponse('Specialization updated successfully', $data);



    }

    /**
     * Delete a Specialization
     */
    public function destroy(string $specialization_name)
    {
        $previous_name = ucfirst(strtolower($specialization_name));
        $specialization = Specialization::where('name', $previous_name)->first();
        if (!$specialization) {
            return $this->errorResponse('Specialization not found', 404);
        }
        $specialization->delete();
        return response()->json(
            [
                'success'=>true,
                'message'=>'Specialization Deleted Successfully',
            ],200
        );
    }
}
