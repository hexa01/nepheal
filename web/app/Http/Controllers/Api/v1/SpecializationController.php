<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Api\v1\BaseController;
use App\Models\Specialization;
use Illuminate\Http\Request;

class SpecializationController extends BaseController
{
    /**
     * View all Specializations.
     */
    public function index()
    {
        $specializations = Specialization::all();

        if ($specializations->isEmpty()) {
            return $this->errorResponse('No specializations found', 404);
        }

        $data = $specializations->map(function ($specialization) {
            return [
                'id' => $specialization->id,
                'name' => $specialization->name,
            ];
        });

        return $this->successResponse('Specializations retrieved successfully', $data);
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
                    $formattedName = ucfirst(strtolower($value));
                    $exists = Specialization::whereRaw('LOWER(name) = ?', [strtolower($formattedName)])->exists();

                    if ($exists) {
                        $fail("$attribute is already taken.");
                    }
                },
            ],
        ]);

        $name = ucfirst(strtolower($request->name));
        $specialization = Specialization::create(['name' => $name]);

        $data = [
            'specialization_id' => $specialization->id,
            'specialization_name' => $specialization->name,
        ];

        return $this->successResponse('Specialization created successfully', $data, 201);
    }

    /**
     * Update Specialization.
     */
    public function update(Request $request, string $specialization_name)
    {
        $previousName = ucfirst(strtolower($specialization_name));
        $specialization = Specialization::where('name', $previousName)->first();

        if (!$specialization) {
            return $this->errorResponse('Specialization not found', 404);
        }

        $request->validate([
            'name' => [
                'required',
                'string',
                function ($attribute, $value, $fail) {
                    $formattedName = ucfirst(strtolower($value));
                    $exists = Specialization::whereRaw('LOWER(name) = ?', [strtolower($formattedName)])->exists();

                    if ($exists) {
                        $fail("$attribute is already taken.");
                    }
                },
            ],
        ]);

        $newName = ucfirst(strtolower($request->name));
        $specialization->update(['name' => $newName]);

        $data = [
            'specialization_id' => $specialization->id,
            'specialization_name' => $specialization->name,
        ];

        return $this->successResponse('Specialization updated successfully', $data);
    }

    /**
     * Delete a Specialization.
     */
    public function destroy(string $specialization_name)
    {
        $name = ucfirst(strtolower($specialization_name));
        $specialization = Specialization::where('name', $name)->first();

        if (!$specialization) {
            return $this->errorResponse('Specialization not found', 404);
        }

        $specialization->delete();

        return $this->successResponse('Specialization deleted successfully', null);
    }
}
