<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\TimezoneSetting;
use Carbon\Carbon;

class TimezoneController extends Controller
{
    /**
     * Display timezone settings page
     */
    public function index()
    {
        $timezoneSettings = TimezoneSetting::all();
        $activeTimezone = TimezoneSetting::getActive();
        $timezoneOptions = TimezoneSetting::getTimezoneOptions();
        
        return view('timezone.index', compact('timezoneSettings', 'activeTimezone', 'timezoneOptions'));
    }

    /**
     * Get current time with timezone
     */
    public function getCurrentTime()
    {
        try {
            $activeTimezone = TimezoneSetting::getActive();
            $currentTime = Carbon::now($activeTimezone->timezone);
            
            return response()->json([
                'success' => true,
                'data' => [
                    'current_time' => $currentTime->format('Y-m-d H:i:s'),
                    'timezone' => $activeTimezone->timezone,
                    'timezone_name' => $activeTimezone->timezone_name,
                    'utc_offset' => $activeTimezone->utc_offset,
                    'timestamp' => $currentTime->timestamp,
                    'formatted' => [
                        'date' => $currentTime->format('Y-m-d'),
                        'time' => $currentTime->format('H:i:s'),
                        'day' => $currentTime->format('l'),
                        'month' => $currentTime->format('F'),
                        'year' => $currentTime->format('Y'),
                        'timezone_display' => $activeTimezone->timezone_name . ' (GMT+' . $activeTimezone->utc_offset . ')'
                    ]
                ]
            ]);
        } catch (\Exception $e) {
            // Fallback to default timezone
            $currentTime = Carbon::now('Asia/Jakarta');
            return response()->json([
                'success' => true,
                'data' => [
                    'current_time' => $currentTime->format('Y-m-d H:i:s'),
                    'timezone' => 'Asia/Jakarta',
                    'timezone_name' => 'WIB',
                    'utc_offset' => 7,
                    'timestamp' => $currentTime->timestamp,
                    'formatted' => [
                        'date' => $currentTime->format('Y-m-d'),
                        'time' => $currentTime->format('H:i:s'),
                        'day' => $currentTime->format('l'),
                        'month' => $currentTime->format('F'),
                        'year' => $currentTime->format('Y'),
                        'timezone_display' => 'WIB (GMT+7)'
                    ]
                ]
            ]);
        }
    }

    /**
     * Update timezone setting
     */
    public function updateTimezone(Request $request)
    {
        try {
            \Log::info('Timezone update request received', [
                'request_data' => $request->all(),
                'headers' => $request->headers->all()
            ]);

            $request->validate([
                'timezone' => 'required|string',
                'timezone_name' => 'required|string',
                'utc_offset' => 'required|integer'
            ]);

            $timezoneOptions = TimezoneSetting::getTimezoneOptions();
            $validTimezone = collect($timezoneOptions)->firstWhere('timezone', $request->timezone);

            if (!$validTimezone) {
                return response()->json([
                    'success' => false,
                    'message' => 'Timezone tidak valid'
                ], 400);
            }

            // Deactivate all timezone settings first
            TimezoneSetting::where('is_active', true)->update(['is_active' => false]);

            // Check if timezone setting already exists
            $timezoneSetting = TimezoneSetting::where('timezone', $request->timezone)->first();
            
            if ($timezoneSetting) {
                // Update existing timezone setting
                $timezoneSetting->update([
                    'timezone_name' => $request->timezone_name,
                    'utc_offset' => $request->utc_offset,
                    'is_active' => true
                ]);
            } else {
                // Create new timezone setting
                $timezoneSetting = TimezoneSetting::create([
                    'timezone' => $request->timezone,
                    'timezone_name' => $request->timezone_name,
                    'utc_offset' => $request->utc_offset,
                    'is_active' => true
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Timezone berhasil diubah ke ' . $timezoneSetting->timezone_name,
                'data' => [
                    'timezone' => $timezoneSetting->timezone,
                    'timezone_name' => $timezoneSetting->timezone_name,
                    'utc_offset' => $timezoneSetting->utc_offset
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update timezone setting (Form request)
     */
    public function updateTimezoneForm(Request $request)
    {
        try {
            \Log::info('Timezone form update request received', [
                'request_data' => $request->all()
            ]);

            $request->validate([
                'timezone' => 'required|string',
                'timezone_name' => 'required|string',
                'utc_offset' => 'required|integer'
            ]);

            $timezoneOptions = TimezoneSetting::getTimezoneOptions();
            $validTimezone = collect($timezoneOptions)->firstWhere('timezone', $request->timezone);

            if (!$validTimezone) {
                return back()->with('error', 'Timezone tidak valid');
            }

            // Deactivate all timezone settings first
            TimezoneSetting::where('is_active', true)->update(['is_active' => false]);

            // Check if timezone setting already exists
            $timezoneSetting = TimezoneSetting::where('timezone', $request->timezone)->first();
            
            if ($timezoneSetting) {
                // Update existing timezone setting
                $timezoneSetting->update([
                    'timezone_name' => $request->timezone_name,
                    'utc_offset' => $request->utc_offset,
                    'is_active' => true
                ]);
            } else {
                // Create new timezone setting
                $timezoneSetting = TimezoneSetting::create([
                    'timezone' => $request->timezone,
                    'timezone_name' => $request->timezone_name,
                    'utc_offset' => $request->utc_offset,
                    'is_active' => true
                ]);
            }

            return back()->with('success', 'Timezone berhasil diubah ke ' . $timezoneSetting->timezone_name);
        } catch (\Exception $e) {
            \Log::error('Error updating timezone: ' . $e->getMessage());
            return back()->with('error', 'Terjadi kesalahan: ' . $e->getMessage());
        }
    }

    /**
     * Get timezone options
     */
    public function getTimezoneOptions()
    {
        $timezoneOptions = TimezoneSetting::getTimezoneOptions();
        
        return response()->json([
            'success' => true,
            'data' => $timezoneOptions
        ]);
    }
}