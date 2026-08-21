<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;
use App\Models\Shift;
use App\Models\Attendance;
use App\Models\TimezoneSetting;

class TimeController extends Controller
{
    /**
     * Get current server time
     */
    public function getCurrentTime(): JsonResponse
    {
        // Get active timezone from database
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
                    'year' => $currentTime->format('Y')
                ]
            ]
        ]);
    }

    /**
     * Get current time with shift information
     */
    public function getTimeWithShifts(): JsonResponse
    {
        // Get active timezone from database
        $activeTimezone = TimezoneSetting::getActive();
        $currentTime = Carbon::now($activeTimezone->timezone);
        $currentTimeFormatted = $currentTime->format('H:i:s');
        
        // Get all active shifts
        $shifts = Shift::all();
        
        $activeShifts = [];
        foreach ($shifts as $shift) {
            $startTime = Carbon::parse($shift->start_time);
            $endTime = Carbon::parse($shift->end_time);
            $currentTimeOnly = Carbon::createFromFormat('H:i:s', $currentTimeFormatted);
            
            $isActive = false;
            if ($startTime->lessThanOrEqualTo($currentTimeOnly) && $endTime->greaterThanOrEqualTo($currentTimeOnly)) {
                $isActive = true;
            }
            
            $activeShifts[] = [
                'id' => $shift->id,
                'name' => $shift->name,
                'start_time' => $shift->start_time,
                'end_time' => $shift->end_time,
                'is_active' => $isActive,
                'late_tolerance' => $shift->late_tolerance
            ];
        }
        
        return response()->json([
            'success' => true,
            'data' => [
                'current_time' => $currentTime->format('Y-m-d H:i:s'),
                'timezone' => $currentTime->timezone->getName(),
                'timestamp' => $currentTime->timestamp,
                'formatted' => [
                    'date' => $currentTime->format('Y-m-d'),
                    'time' => $currentTime->format('H:i:s'),
                    'day' => $currentTime->format('l'),
                    'month' => $currentTime->format('F'),
                    'year' => $currentTime->format('Y')
                ],
                'shifts' => $activeShifts
            ]
        ]);
    }

    /**
     * Get time with attendance status for current user
     */
    public function getTimeWithAttendance(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Get active timezone from database
        $activeTimezone = TimezoneSetting::getActive();
        $currentTime = Carbon::now($activeTimezone->timezone);
        $today = $currentTime->format('Y-m-d');
        
        // Get today's attendance for the user
        $attendance = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->with('shift')
            ->first();
        
        $attendanceStatus = null;
        if ($attendance) {
            $attendanceStatus = [
                'id' => $attendance->id,
                'date' => $attendance->date,
                'check_in' => $attendance->check_in ? $attendance->check_in->format('Y-m-d H:i:s') : null,
                'check_out' => $attendance->check_out ? $attendance->check_out->format('Y-m-d H:i:s') : null,
                'is_late' => $attendance->is_late,
                'shift' => $attendance->shift ? [
                    'id' => $attendance->shift->id,
                    'name' => $attendance->shift->name,
                    'start_time' => $attendance->shift->start_time,
                    'end_time' => $attendance->shift->end_time
                ] : null
            ];
        }
        
        return response()->json([
            'success' => true,
            'data' => [
                'current_time' => $currentTime->format('Y-m-d H:i:s'),
                'timezone' => $currentTime->timezone->getName(),
                'timestamp' => $currentTime->timestamp,
                'formatted' => [
                    'date' => $currentTime->format('Y-m-d'),
                    'time' => $currentTime->format('H:i:s'),
                    'day' => $currentTime->format('l'),
                    'month' => $currentTime->format('F'),
                    'year' => $currentTime->format('Y')
                ],
                'attendance' => $attendanceStatus
            ]
        ]);
    }

    /**
     * Get time with all users' attendance status
     */
    public function getTimeWithAllAttendance(): JsonResponse
    {
        // Get active timezone from database
        $activeTimezone = TimezoneSetting::getActive();
        $currentTime = Carbon::now($activeTimezone->timezone);
        $today = $currentTime->format('Y-m-d');
        
        // Get all today's attendance records
        $attendances = Attendance::where('date', $today)
            ->with(['user', 'shift'])
            ->get();
        
        $attendanceData = [];
        foreach ($attendances as $attendance) {
            $attendanceData[] = [
                'id' => $attendance->id,
                'user' => [
                    'id' => $attendance->user->id,
                    'name' => $attendance->user->name,
                    'email' => $attendance->user->email
                ],
                'shift' => $attendance->shift ? [
                    'id' => $attendance->shift->id,
                    'name' => $attendance->shift->name,
                    'start_time' => $attendance->shift->start_time,
                    'end_time' => $attendance->shift->end_time
                ] : null,
                'check_in' => $attendance->check_in ? $attendance->check_in->format('Y-m-d H:i:s') : null,
                'check_out' => $attendance->check_out ? $attendance->check_out->format('Y-m-d H:i:s') : null,
                'is_late' => $attendance->is_late
            ];
        }
        
        return response()->json([
            'success' => true,
            'data' => [
                'current_time' => $currentTime->format('Y-m-d H:i:s'),
                'timezone' => $currentTime->timezone->getName(),
                'timestamp' => $currentTime->timestamp,
                'formatted' => [
                    'date' => $currentTime->format('Y-m-d'),
                    'time' => $currentTime->format('H:i:s'),
                    'day' => $currentTime->format('l'),
                    'month' => $currentTime->format('F'),
                    'year' => $currentTime->format('Y')
                ],
                'attendances' => $attendanceData
            ]
        ]);
    }
}
