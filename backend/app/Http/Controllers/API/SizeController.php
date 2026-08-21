<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Size;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class SizeController extends Controller
{
    public function index()
    {
        $sizes = Size::all();
        return response()->json(['data' => $sizes]);
    }

    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'nullable|string'
            ]);

            $size = Size::create([
                'name' => $validated['name'],
                'code' => Str::upper(Str::slug($validated['name'])),
                'description' => $validated['description'] ?? null
            ]);

            return response()->json([
                'message' => 'Size created successfully',
                'data' => $size
            ], 201);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        }
    }

    public function show(Size $size)
    {
        return response()->json(['data' => $size]);
    }

    public function update(Request $request, Size $size)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'nullable|string'
            ]);

            $size->update([
                'name' => $validated['name'],
                'code' => Str::upper(Str::slug($validated['name'])),
                'description' => $validated['description'] ?? $size->description
            ]);

            return response()->json([
                'message' => 'Size updated successfully',
                'data' => $size
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        }
    }

    public function destroy(Size $size)
    {
        $size->delete();
        return response()->json(['message' => 'Size deleted successfully']);
    }
}