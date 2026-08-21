<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\LocationSetting;
use Illuminate\Support\Facades\Validator;

class LocationController extends Controller
{
    /**
     * Display location settings page
     */
    public function index()
    {
        $locationSettings = LocationSetting::orderBy('created_at', 'desc')->get();
        $activeLocation = LocationSetting::getActive();
        
        return view('location.index', compact('locationSettings', 'activeLocation'));
    }

    /**
     * Store a new location setting
     */
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
                'radius_meters' => 'required|integer|min:1|max:10000',
                'address' => 'nullable|string',
                'city' => 'nullable|string',
                'province' => 'nullable|string',
                'is_active' => 'boolean'
            ]);

            if ($validator->fails()) {
                return back()->withErrors($validator)->withInput();
            }

            // If this is set as active, deactivate others
            if ($request->is_active) {
                LocationSetting::where('is_active', true)->update(['is_active' => false]);
            }

            $locationSetting = LocationSetting::create($request->all());

            return back()->with('success', 'Location setting created successfully');
        } catch (\Exception $e) {
            \Log::error('Error creating location setting: ' . $e->getMessage());
            return back()->with('error', 'Failed to create location setting: ' . $e->getMessage());
        }
    }

    /**
     * Update location setting
     */
    public function update(Request $request, LocationSetting $locationSetting)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
                'radius_meters' => 'required|integer|min:1|max:10000',
                'address' => 'nullable|string',
                'city' => 'nullable|string',
                'province' => 'nullable|string',
                'is_active' => 'boolean'
            ]);

            if ($validator->fails()) {
                return back()->withErrors($validator)->withInput();
            }

            // If this is set as active, deactivate others
            if ($request->is_active) {
                LocationSetting::where('id', '!=', $locationSetting->id)->update(['is_active' => false]);
            }

            $locationSetting->update($request->all());

            return back()->with('success', 'Location setting updated successfully');
        } catch (\Exception $e) {
            \Log::error('Error updating location setting: ' . $e->getMessage());
            return back()->with('error', 'Failed to update location setting: ' . $e->getMessage());
        }
    }

    /**
     * Set location as active
     */
    public function setActive(Request $request, LocationSetting $locationSetting)
    {
        try {
            $locationSetting->setActive();
            return back()->with('success', 'Location setting activated successfully');
        } catch (\Exception $e) {
            \Log::error('Error activating location setting: ' . $e->getMessage());
            return back()->with('error', 'Failed to activate location setting: ' . $e->getMessage());
        }
    }

    /**
     * Delete location setting
     */
    public function destroy(LocationSetting $locationSetting)
    {
        try {
            if ($locationSetting->is_active) {
                return back()->with('error', 'Cannot delete active location setting');
            }

            $locationSetting->delete();
            return back()->with('success', 'Location setting deleted successfully');
        } catch (\Exception $e) {
            \Log::error('Error deleting location setting: ' . $e->getMessage());
            return back()->with('error', 'Failed to delete location setting: ' . $e->getMessage());
        }
    }

    // API Methods

    /**
     * Get active location setting for API
     */
    public function getActiveLocation()
    {
        try {
            $activeLocation = LocationSetting::getActive();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $activeLocation->id,
                    'name' => $activeLocation->name,
                    'description' => $activeLocation->description,
                    'latitude' => (float) $activeLocation->latitude,
                    'longitude' => (float) $activeLocation->longitude,
                    'radius_meters' => $activeLocation->radius_meters,
                    'address' => $activeLocation->address,
                    'city' => $activeLocation->city,
                    'province' => $activeLocation->province,
                    'coordinates_dms' => $activeLocation->getCoordinatesInDMS(),
                    'google_maps_url' => $activeLocation->getGoogleMapsUrl(),
                    'formatted_address' => $activeLocation->getFormattedAddress()
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get location setting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Check if coordinates are within allowed radius (GET method for testing)
     */
    public function checkLocationGet($latitude, $longitude)
    {
        try {
            $activeLocation = LocationSetting::getActive();
            $latitude = (float) $latitude;
            $longitude = (float) $longitude;

            $distance = $activeLocation->calculateDistance($latitude, $longitude);
            $isWithinRadius = $activeLocation->isWithinRadius($latitude, $longitude);

            return response()->json([
                'success' => true,
                'data' => [
                    'is_within_radius' => $isWithinRadius,
                    'distance_meters' => round($distance, 2),
                    'allowed_radius_meters' => $activeLocation->radius_meters,
                    'user_coordinates' => [
                        'latitude' => $latitude,
                        'longitude' => $longitude
                    ],
                    'office_coordinates' => [
                        'latitude' => (float) $activeLocation->latitude,
                        'longitude' => (float) $activeLocation->longitude
                    ],
                    'office_info' => [
                        'name' => $activeLocation->name,
                        'address' => $activeLocation->getFormattedAddress(),
                        'google_maps_url' => $activeLocation->getGoogleMapsUrl()
                    ]
                ]
            ]);
        } catch (\Exception $e) {
            \Log::error('Error checking location (GET): ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to check location: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Check if coordinates are within allowed radius
     */
    public function checkLocation(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid coordinates',
                    'errors' => $validator->errors()
                ], 400);
            }

            $activeLocation = LocationSetting::getActive();
            $latitude = $request->latitude;
            $longitude = $request->longitude;

            $distance = $activeLocation->calculateDistance($latitude, $longitude);
            $isWithinRadius = $activeLocation->isWithinRadius($latitude, $longitude);

            return response()->json([
                'success' => true,
                'data' => [
                    'is_within_radius' => $isWithinRadius,
                    'distance_meters' => round($distance, 2),
                    'allowed_radius_meters' => $activeLocation->radius_meters,
                    'user_coordinates' => [
                        'latitude' => $latitude,
                        'longitude' => $longitude
                    ],
                    'office_coordinates' => [
                        'latitude' => (float) $activeLocation->latitude,
                        'longitude' => (float) $activeLocation->longitude
                    ],
                    'office_info' => [
                        'name' => $activeLocation->name,
                        'address' => $activeLocation->getFormattedAddress(),
                        'google_maps_url' => $activeLocation->getGoogleMapsUrl()
                    ]
                ]
            ]);
        } catch (\Exception $e) {
            \Log::error('Error checking location: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to check location: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get all location settings for API
     */
    public function getAllLocations()
    {
        try {
            $locations = LocationSetting::orderBy('created_at', 'desc')->get();
            
            $data = $locations->map(function ($location) {
                return [
                    'id' => $location->id,
                    'name' => $location->name,
                    'description' => $location->description,
                    'latitude' => (float) $location->latitude,
                    'longitude' => (float) $location->longitude,
                    'radius_meters' => $location->radius_meters,
                    'is_active' => $location->is_active,
                    'address' => $location->address,
                    'city' => $location->city,
                    'province' => $location->province,
                    'coordinates_dms' => $location->getCoordinatesInDMS(),
                    'google_maps_url' => $location->getGoogleMapsUrl(),
                    'formatted_address' => $location->getFormattedAddress(),
                    'created_at' => $location->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $location->updated_at->format('Y-m-d H:i:s')
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to get location settings: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update location setting via API
     */
    public function updateLocation(Request $request, LocationSetting $locationSetting)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
                'radius_meters' => 'required|integer|min:1|max:10000',
                'address' => 'nullable|string',
                'city' => 'nullable|string',
                'province' => 'nullable|string',
                'is_active' => 'boolean'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 400);
            }

            // If this is set as active, deactivate others
            if ($request->is_active) {
                LocationSetting::where('id', '!=', $locationSetting->id)->update(['is_active' => false]);
            }

            $locationSetting->update($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Location setting updated successfully',
                'data' => [
                    'id' => $locationSetting->id,
                    'name' => $locationSetting->name,
                    'description' => $locationSetting->description,
                    'latitude' => (float) $locationSetting->latitude,
                    'longitude' => (float) $locationSetting->longitude,
                    'radius_meters' => $locationSetting->radius_meters,
                    'is_active' => $locationSetting->is_active,
                    'address' => $locationSetting->address,
                    'city' => $locationSetting->city,
                    'province' => $locationSetting->province,
                    'coordinates_dms' => $locationSetting->getCoordinatesInDMS(),
                    'google_maps_url' => $locationSetting->getGoogleMapsUrl(),
                    'formatted_address' => $locationSetting->getFormattedAddress()
                ]
            ]);
        } catch (\Exception $e) {
            \Log::error('Error updating location setting via API: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update location setting: ' . $e->getMessage()
            ], 500);
        }
    }
}