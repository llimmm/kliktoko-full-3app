<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Shift;
use App\Models\Attendance;
use App\Models\Leave;
use App\Models\User;
use App\Models\TimezoneSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class ShiftController extends Controller
{
    public function updateTimes(Request $request)
    {
        $request->validate([
            'shifts.*.start_time' => 'required|date_format:H:i',
            'shifts.*.end_time' => 'required|date_format:H:i',
            'shifts.*.late_tolerance' => 'nullable|integer|min:0|max:180',
        ]);

        try {
            foreach ($request->shifts as $id => $times) {
                $shift = Shift::findOrFail($id);
                
                $startTime = Carbon::createFromFormat('H:i', $times['start_time']);
                $endTime = Carbon::createFromFormat('H:i', $times['end_time']);
                $shift->start_time = $startTime->format('H:i:s');
                $shift->end_time = $endTime->format('H:i:s');
                $shift->check_in_time = $startTime->format('H:i:s');
                $shift->check_out_time = $endTime->format('H:i:s');
                $shift->late_tolerance = isset($times['late_tolerance']) ? $times['late_tolerance'] : 15;
                
                $shift->save();
            }

            return redirect()->route('shifts.index')
                ->with('success', 'Waktu shift berhasil diperbarui')
                ->with('activeTab', 'settings');

        } catch (\Exception $e) {
            return redirect()->route('shifts.index')
                ->with('error', 'Terjadi kesalahan saat memperbarui shift: ' . $e->getMessage())
                ->with('activeTab', 'settings');
        }
    }

    public function detail(Request $request, User $user)
    {
        // Check if user exists
        if (!$user) {
            return redirect()->route('shifts.index')->with('error', 'User tidak ditemukan');
        }
        
        // Get active timezone from database
        $activeTimezone = TimezoneSetting::getActive();
        $now = Carbon::now($activeTimezone->timezone);
        $month = $request->get('month', $now->format('Y-m'));
        $date = Carbon::createFromFormat('Y-m', $month, $activeTimezone->timezone);
        
        $monthlyStats = new \stdClass();
        $monthlyStats->total_shifts = Attendance::where('user_id', $user->id)
            ->whereYear('date', $date->year)
            ->whereMonth('date', $date->month)
            ->count();
            
        $monthlyStats->leave_days = Leave::where('user_id', $user->id)
            ->whereYear('date', $date->year)
            ->whereMonth('date', $date->month)
            ->count();
            
        $monthlyStats->shift_1_count = Attendance::where('user_id', $user->id)
            ->whereYear('date', $date->year)
            ->whereMonth('date', $date->month)
            ->where('shift_id', 1)
            ->count();
            
        $monthlyStats->shift_2_count = Attendance::where('user_id', $user->id)
            ->whereYear('date', $date->year)
            ->whereMonth('date', $date->month)
            ->where('shift_id', 2)
            ->count();
            
        $totalMinutes = Attendance::where('user_id', $user->id)
            ->whereYear('date', $date->year)
            ->whereMonth('date', $date->month)
            ->whereNotNull('check_out')
            ->get()
            ->sum(function ($attendance) {
                return abs($attendance->check_out->diffInMinutes($attendance->check_in));
            });
            
        $hours = floor($totalMinutes / 60);
        $minutes = $totalMinutes % 60;
        $monthlyStats->total_hours = sprintf('%d jam %d menit', $hours, $minutes);

        $monthlyStats->base_salary = $monthlyStats->total_shifts * 25000;
        $monthlyStats->overtime_pay = 0;
        $monthlyStats->total_salary = $monthlyStats->base_salary + $monthlyStats->overtime_pay;
            
        $attendances = Attendance::with('shift')
            ->where('user_id', $user->id)
            ->whereYear('date', $date->year)
            ->whereMonth('date', $date->month)
            ->orderBy('date', 'desc')
            ->get();
            
        // Check if attendances exist
        if ($attendances->isEmpty()) {
            return view('shifts.detail', compact('user', 'month', 'monthlyStats', 'attendances'))
                ->with('info', 'Tidak ada data kehadiran untuk bulan ini');
        }
            
        $attendances = $attendances->map(function ($attendance) {
                // Hitung durasi
                $duration = null;
                if ($attendance->check_in && $attendance->check_out) {
                    $totalMinutes = abs($attendance->check_out->diffInMinutes($attendance->check_in));
                    $hours = floor($totalMinutes / 60);
                    $minutes = $totalMinutes % 60;
                    $duration = $hours . ' jam ' . $minutes . ' menit';
                } elseif ($attendance->check_in && !$attendance->check_out) {
                    // Jika belum checkout, hitung dari check-in sampai sekarang
                    $activeTimezone = TimezoneSetting::getActive();
                    $now = Carbon::now($activeTimezone->timezone);
                    $totalMinutes = abs($now->diffInMinutes($attendance->check_in));
                    $hours = floor($totalMinutes / 60);
                    $minutes = $totalMinutes % 60;
                    $duration = $hours . ' jam ' . $minutes . ' menit';
                }
                
                $attendance->duration = $duration;
                return $attendance;
            });
            
        return view('shifts.detail', compact('user', 'month', 'monthlyStats', 'attendances'));
    }

    public function index(Request $request)
    {
        $shifts = Shift::orderBy('id')->get();
        $user = Auth::user();
        
        // Get active timezone from database
        $activeTimezone = TimezoneSetting::getActive();
        $today = Carbon::now($activeTimezone->timezone)->toDateString();
        $currentMonth = Carbon::now($activeTimezone->timezone);

        // Active Shifts Data
        $activeAttendance = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->whereNull('check_out')
            ->first();

        $activeUsers = Attendance::with('user', 'shift')
            ->where('date', $today)
            ->whereNull('check_out')
            ->get()
            ->map(function ($attendance) {
                $user = $attendance->user;
                $user->attendances = collect([$attendance]);
                return $user;
            })->unique();

        $leaveUsers = Leave::with('user')
            ->where('date', $today)
            ->get()
            ->map(function ($leave) {
                $user = $leave->user;
                $user->leave = $leave;
                return $user;
            })->unique();

        // Monthly Summary Data
        $users = User::with(['attendances' => function ($query) use ($currentMonth) {
            $query->whereYear('date', $currentMonth->year)
                  ->whereMonth('date', $currentMonth->month)
                  ->with('shift');
        }, 'payrolls' => function ($query) use ($currentMonth) {
            $query->whereYear('date', $currentMonth->year)
                  ->whereMonth('date', $currentMonth->month);
        }])->where('role', 'karyawan')->get();

        $summaries = $users->map(function ($user) use ($currentMonth) {
            $attendances = $user->attendances;
            
            $summary = new \stdClass();
            $summary->user = $user;
            $summary->total_shifts = $attendances->count();
            $summary->shift_1_count = $attendances->where('shift_id', 1)->count();
            $summary->shift_2_count = $attendances->where('shift_id', 2)->count();
            $summary->late_count = $attendances->where('is_late', true)->count();
            
            $summary->leave_days = Leave::where('user_id', $user->id)
                ->whereYear('date', $currentMonth->year)
                ->whereMonth('date', $currentMonth->month)
                ->count();

            $totalMinutes = $attendances->sum(function ($attendance) {
                if ($attendance->check_out) {
                    return abs($attendance->check_out->diffInMinutes($attendance->check_in));
                }
                return 0;
            });
            
            $hours = floor($totalMinutes / 60);
            $minutes = $totalMinutes % 60;
            $summary->total_hours = sprintf('%d jam %d menit', $hours, $minutes);

            return $summary;
        });

        $stats = new \stdClass();
        $stats->total_employees = $users->count();
        $stats->total_shifts = $summaries->sum('total_shifts');
        $stats->avg_shifts_per_employee = $stats->total_employees > 0 
            ? $stats->total_shifts / $stats->total_employees 
            : 0;
        $stats->total_salary_payout = $summaries->sum('total_salary');
        $stats->total_late_count = $summaries->sum('late_count');

        return view('shifts.index', compact('shifts', 'activeAttendance', 'activeUsers', 'leaveUsers', 'summaries', 'stats'));
    }
}