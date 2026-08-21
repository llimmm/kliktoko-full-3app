<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Leave;
use App\Models\Shift;
use App\Models\TimezoneSetting;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;

class ShiftController extends Controller
{
    public function checkIn(Request $request): JsonResponse
    {
        $request->validate([
            'photo' => 'required|image|mimes:jpeg,png,jpg|max:2048'
        ]);

        $user = $request->user();
        
        // Get active timezone from database
        $activeTimezone = TimezoneSetting::getActive();
        $now = Carbon::now($activeTimezone->timezone);
        
        // Cek apakah sudah ada attendance hari ini
        $today = $now->toDateString();
        $existingAttendance = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->first();
            
        if ($existingAttendance) {
            return response()->json([
                'message' => 'Anda sudah melakukan check-in hari ini'
            ], 400);
        }
        
        // Deteksi shift berdasarkan waktu check-in
        $currentTime = $now->format('H:i:s');
        $shifts = Shift::all();
        $detectedShift = null;
        
        foreach ($shifts as $shift) {
            $startTime = Carbon::parse($shift->start_time)->format('H:i:s');
            $endTime = Carbon::parse($shift->end_time)->format('H:i:s');
            
            if ($currentTime >= $startTime && $currentTime <= $endTime) {
                $detectedShift = $shift;
                break;
            }
        }
        
        if (!$detectedShift) {
            return response()->json([
                'message' => 'Tidak ada shift aktif pada waktu ini'
            ], 400);
        }
        
        // Upload foto
        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photo = $request->file('photo');
            $fileName = time() . '_' . $user->id . '.' . $photo->getClientOriginalExtension();
            $photoPath = $photo->storeAs('check-in-photos', $fileName, 'public');
        }

        // Buat attendance baru
        $attendance = new Attendance([
            'user_id' => $user->id,
            'shift_id' => $detectedShift->id,
            'date' => $today,
            'check_in' => $now,
            'check_in_photo' => $photoPath
        ]);
        
        // Cek keterlambatan berdasarkan toleransi
        $shiftStart = Carbon::parse($detectedShift->start_time);
        $toleranceMinutes = $detectedShift->late_tolerance;
        $lateThreshold = $shiftStart->copy()->addMinutes($toleranceMinutes);
        $attendance->is_late = $now->isAfter($lateThreshold);
        
        $attendance->save();
        
        // Update status absensi user
        $user->update([
            'is_checked_in' => true,
            'last_check_in' => $now
        ]);
        
        return response()->json([
            'message' => 'Check-in berhasil',
            'data' => [
                'attendance' => $attendance,
                'user' => $user,
                'photo_url' => $photoPath ? asset('storage/' . $photoPath) : null
            ]
        ]);
    }
    
    public function getShifts(): JsonResponse
    {
        $shifts = Shift::all();
        return response()->json([
            'data' => $shifts
        ]);
    }

    public function getUserShiftStatus(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Get active timezone from database
        $activeTimezone = TimezoneSetting::getActive();
        $now = Carbon::now($activeTimezone->timezone);
        $today = $now->toDateString();
        $currentTime = $now->format('H:i:s');
        
        // Deteksi shift aktif saat ini
        $shifts = Shift::all();
        $activeShift = null;
        
        foreach ($shifts as $shift) {
            $startTime = Carbon::parse($shift->start_time)->format('H:i:s');
            $endTime = Carbon::parse($shift->end_time)->format('H:i:s');
            
            if ($currentTime >= $startTime && $currentTime <= $endTime) {
                $activeShift = $shift;
                break;
            }
        }
        
        if (!$activeShift) {
            return response()->json([
                'message' => 'Shift tidak ada, silahkan istirahat',
                'is_active' => false,
                'data' => null
            ]);
        }
        
        // Cek attendance hari ini
        $attendance = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->first();
            
        if (!$attendance) {
            return response()->json([
                'message' => 'Anda belum absen di shift ' . $activeShift->id,
                'is_active' => false,
                'data' => null
            ]);
        }
        
        // Hitung durasi shift
        $shift = Shift::find($attendance->shift_id);
        $duration = null;
        
        if ($attendance->check_in) {
            $startTime = Carbon::parse($attendance->check_in);
            $endTime = $attendance->check_out ? Carbon::parse($attendance->check_out) : $now;
            $duration = $endTime->diffInHours($startTime) . ' jam ' . ($endTime->diffInMinutes($startTime) % 60) . ' menit';
        }
        
        // Cek status checkout
        if ($attendance->check_out) {
            return response()->json([
                'message' => 'User sudah checkout',
                'is_active' => false,
                'data' => [
                    'shift_number' => $shift->id,
                    'shift_time' => Carbon::parse($shift->start_time)->format('H:i') . ' - ' . Carbon::parse($shift->end_time)->format('H:i'),
                    'duration' => $duration,
                    'is_late' => $attendance->is_late,
                    'check_in' => $attendance->check_in,
                    'check_out' => $attendance->check_out
                ]
            ]);
        }
        
        return response()->json([
            'message' => 'User sedang aktif',
            'is_active' => true,
            'data' => [
                'shift_number' => $shift->id,
                'shift_time' => Carbon::parse($shift->start_time)->format('H:i') . ' - ' . Carbon::parse($shift->end_time)->format('H:i'),
                'duration' => $duration,
                'is_late' => $attendance->is_late,
                'check_in' => $attendance->check_in,
                'check_out' => $attendance->check_out
            ]
        ]);
    }

    public function getMonthlyShiftHistory(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Get active timezone from database
        $activeTimezone = TimezoneSetting::getActive();
        $now = Carbon::now($activeTimezone->timezone);
        $date = $request->get('date', $now->format('Y-m'));
        $startDate = Carbon::createFromFormat('Y-m', $date, $activeTimezone->timezone)->startOfMonth();
        $endDate = Carbon::createFromFormat('Y-m', $date, $activeTimezone->timezone)->endOfMonth();

        $attendances = Attendance::with('shift')
            ->where('user_id', $user->id)
            ->whereBetween('date', [$startDate, $endDate])
            ->orderBy('date', 'desc')
            ->get()
            ->map(function ($attendance) use ($activeTimezone) {
                return [
                    'tanggal' => $attendance->date->format('Y-m-d'),
                    'nama_shift' => 'Shift ' . $attendance->shift_id,
                    'waktu_shift' => Carbon::parse($attendance->shift->start_time)->format('H:i') . ' - ' . 
                                    Carbon::parse($attendance->shift->end_time)->format('H:i'),
                    'status' => $attendance->is_late ? 'Terlambat' : 'Tepat Waktu',
                    'check_in' => $attendance->check_in->format('H:i'),
                    'check_out' => $attendance->check_out ? $attendance->check_out->format('H:i') : null,
                    'durasi' => $this->calculateDuration(
                        $attendance->check_in,
                        $attendance->check_out ?: Carbon::now($activeTimezone->timezone)
                    )
                ];
            });

        return response()->json([
            'message' => 'Berhasil mendapatkan history shift',
            'data' => [
                'bulan' => $date,
                'total_hari_kerja' => $attendances->count(),
                'total_terlambat' => $attendances->where('status', 'Terlambat')->count(),
                'history' => $attendances
            ]
        ]);
    }

    private function calculateDuration($startTime, $endTime): string
    {
        $totalMinutes = $endTime->diffInMinutes($startTime);
        $hours = floor($totalMinutes / 60);
        $minutes = $totalMinutes % 60;
        return ($hours > 0 ? $hours : '0') . ' jam ' . $minutes . ' menit';
    }

    public function checkOut(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Get active timezone from database
        $activeTimezone = TimezoneSetting::getActive();
        $now = Carbon::now($activeTimezone->timezone);
        $today = $now->toDateString();
        
        $attendance = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->whereNull('check_out')
            ->firstOrFail();
            
        $attendance->check_out = $now;

        // Hapus foto check-in
        if ($attendance->check_in_photo) {
            Storage::disk('public')->delete($attendance->check_in_photo);
            $attendance->check_in_photo = null;
        }

        $attendance->save();
        
        // Reset status absensi user
        $user->update([
            'is_checked_in' => false,
            'last_check_in' => null
        ]);
        
        return response()->json([
            'message' => 'Check-out berhasil',
            'data' => [
                'attendance' => $attendance,
                'user' => $user
            ]
        ]);
    }

    /**
     * Mengajukan cuti untuk satu tanggal.
     *
     * Rutenya sudah terdaftar sejak lama (routes/api.php: leave/request) tapi
     * metodenya tidak pernah ditulis, sehingga endpoint ini mengembalikan 500
     * selama ini. Tabel leaves menyimpan SATU baris per hari cuti — tidak ada
     * kolom rentang tanggal.
     */
    public function requestLeave(Request $request): JsonResponse
    {
        $request->validate([
            'date' => 'required|date',
            'reason' => 'nullable|string|max:500',
        ]);

        $user = $request->user();

        $activeTimezone = TimezoneSetting::getActive();
        $tanggal = Carbon::parse($request->date, $activeTimezone->timezone)->startOfDay();

        // Satu tanggal hanya boleh sekali. Tanpa penjaga ini karyawan bisa
        // menumpuk pengajuan untuk hari yang sama tanpa batas.
        $sudahAda = Leave::where('user_id', $user->id)
            ->whereDate('date', $tanggal->format('Y-m-d'))
            ->first();

        if ($sudahAda) {
            return response()->json([
                'message' => 'Anda sudah mengajukan cuti untuk tanggal ' . $tanggal->format('d-m-Y'),
                'data' => null
            ], 400);
        }

        // status TIDAK diambil dari request. Kolom itu ada di $fillable, jadi
        // meneruskan input mentah akan membuat karyawan bisa menyetujui
        // cutinya sendiri dengan mengirim status=approved.
        $leave = Leave::create([
            'user_id' => $user->id,
            'date' => $tanggal->format('Y-m-d'),
            'status' => Leave::STATUS_PENDING,
            'reason' => $request->reason,
        ]);

        return response()->json([
            'message' => 'Pengajuan cuti berhasil dikirim',
            'data' => $this->formatLeave($leave)
        ], 201);
    }

    /**
     * Riwayat pengajuan cuti milik karyawan yang sedang login.
     *
     * Bentuknya {message, data: [...]} dengan data berupa array DATAR.
     * Klien Flutter (ApiService.getLeaveHistory) menerima array top-level,
     * {data:[...]}, atau {history:[...]} — tapi TIDAK mengenali bentuk
     * bersarang {data:{history:[...]}} yang dipakai getMonthlyShiftHistory.
     */
    public function getLeaveHistory(Request $request): JsonResponse
    {
        $user = $request->user();

        $leaves = Leave::where('user_id', $user->id)
            ->orderBy('date', 'desc')
            ->get()
            ->map(fn ($leave) => $this->formatLeave($leave));

        $activeTimezone = TimezoneSetting::getActive();
        $bulanIni = Carbon::now($activeTimezone->timezone)->format('m');

        return response()->json([
            'message' => 'Berhasil mendapatkan riwayat cuti',
            'sisa_cuti_bulan_ini' => Leave::getRemainingLeaves($user->id, $bulanIni),
            'data' => $leaves
        ]);
    }

    /**
     * Riwayat absensi mentah milik karyawan yang sedang login.
     *
     * Sengaja array DATAR di dalam 'data', bukan bentuk teragregasi seperti
     * getMonthlyShiftHistory: AttendanceApiService.checkAttendanceStatus hanya
     * mengenali array top-level atau {data:[...]}, lalu menelusuri tiap baris
     * mencari tanggal hari ini. Bentuk bersarang menghasilkan daftar kosong
     * tanpa error apa pun — kegagalan paling senyap yang bisa terjadi di sini.
     *
     * Tiap baris membawa check_in dan check_in_time sekaligus karena
     * AttendanceModel.fromJson membaca salah satu dari keduanya. is_late
     * selalu disertakan: kalau tidak ada, app menghitungnya sendiri memakai
     * ambang 07:30/14:30 yang di-hardcode dan tidak cocok dengan database.
     */
    public function getAttendanceHistory(Request $request): JsonResponse
    {
        $user = $request->user();

        $attendances = Attendance::with('shift')
            ->where('user_id', $user->id)
            ->orderBy('date', 'desc')
            ->orderBy('check_in', 'desc')
            ->get()
            ->map(function ($attendance) {
                return [
                    'id' => $attendance->id,
                    'date' => $attendance->date->format('Y-m-d'),
                    'shift_id' => $attendance->shift_id,
                    'shift' => $attendance->shift ? [
                        'id' => $attendance->shift->id,
                        'name' => $attendance->shift->name,
                        'start_time' => $attendance->shift->start_time?->format('H:i:s'),
                        'end_time' => $attendance->shift->end_time?->format('H:i:s'),
                    ] : null,
                    'check_in' => $attendance->check_in?->format('Y-m-d H:i:s'),
                    'check_out' => $attendance->check_out?->format('Y-m-d H:i:s'),
                    'check_in_time' => $attendance->check_in?->format('H:i:s'),
                    'check_out_time' => $attendance->check_out?->format('H:i:s'),
                    'is_late' => (bool) $attendance->is_late,
                    // Masih di dalam shift: sudah masuk, belum pulang.
                    'is_checked_in' => $attendance->check_in !== null
                        && $attendance->check_out === null,
                    'check_in_photo' => $attendance->check_in_photo,
                ];
            });

        return response()->json([
            'message' => 'Berhasil mendapatkan riwayat absensi',
            'data' => $attendances
        ]);
    }

    /**
     * Bentuk satu baris cuti. Tanggal diformat eksplisit, bukan diserahkan ke
     * serialisasi bawaan yang menggeser tanggal mundur satu hari ke UTC.
     */
    private function formatLeave(Leave $leave): array
    {
        return [
            'id' => $leave->id,
            'date' => $leave->date->format('Y-m-d'),
            'tanggal' => $leave->date->format('d-m-Y'),
            'status' => $leave->status,
            'status_label' => match ($leave->status) {
                Leave::STATUS_APPROVED => 'Disetujui',
                Leave::STATUS_REJECTED => 'Ditolak',
                default => 'Menunggu',
            },
            'reason' => $leave->reason,
            'created_at' => $leave->created_at?->format('Y-m-d H:i:s'),
        ];
    }
}
