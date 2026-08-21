<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Payroll;
use App\Models\TimezoneSetting;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Slip gaji untuk app employee.
 *
 * Tabel `payrolls` sudah ada sejak awal lengkap dengan base_salary,
 * overtime_pay, deductions, bonus, dan total_hours — tapi tidak pernah punya
 * controller maupun rute, jadi slip gaji tidak mungkin ditampilkan di mana
 * pun. Ini yang menutup lubang itu.
 *
 * Hanya baca. Pembuatan dan penyuntingan slip adalah pekerjaan panel admin,
 * dan panel itu belum punya halamannya — dicatat sebagai pekerjaan terpisah.
 */
class PayrollController extends Controller
{
    /**
     * Riwayat slip gaji milik karyawan yang sedang login.
     *
     * Bentuknya {message, data: [...]} dengan data berupa array DATAR, sama
     * seperti endpoint cuti dan absensi — parser generik di sisi Flutter
     * mengenali array top-level, {data:[...]}, atau {history:[...]}, tapi
     * tidak mengenali bentuk bersarang.
     *
     * Filter opsional ?year=2026 karena tabelnya hanya punya kolom `date`,
     * tanpa kolom periode tersendiri.
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'year' => 'nullable|integer|min:2000|max:2100',
        ]);

        $user = $request->user();

        $query = Payroll::where('user_id', $user->id);

        if ($request->filled('year')) {
            $query->whereYear('date', $request->year);
        }

        $payrolls = $query->orderBy('date', 'desc')
            ->get()
            ->map(fn ($payroll) => $this->formatPayroll($payroll));

        return response()->json([
            'message' => 'Berhasil mendapatkan riwayat slip gaji',
            'total_slip' => $payrolls->count(),
            'data' => $payrolls,
        ]);
    }

    /**
     * Detail satu slip gaji.
     *
     * Dibatasi ke milik karyawan yang sedang login — tanpa penjaga ini siapa
     * pun yang punya token bisa membaca gaji rekan kerjanya hanya dengan
     * menaikkan angka id.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $payroll = Payroll::where('user_id', $user->id)
            ->where('id', $id)
            ->first();

        if (!$payroll) {
            return response()->json([
                'message' => 'Slip gaji tidak ditemukan',
                'data' => null,
            ], 404);
        }

        return response()->json([
            'message' => 'Berhasil mendapatkan slip gaji',
            'data' => $this->formatPayroll($payroll),
        ]);
    }

    /**
     * Bentuk satu slip.
     *
     * Tanggal diformat eksplisit, bukan diserahkan ke serialisasi bawaan yang
     * menggeser tanggal mundur satu hari ke UTC. Nilai uang dikirim sebagai
     * angka mentah dan juga sebagai teks siap tampil, supaya app tidak perlu
     * mengulang aturan format rupiah.
     */
    private function formatPayroll(Payroll $payroll): array
    {
        $total = $payroll->calculateTotalSalary();

        $activeTimezone = TimezoneSetting::getActive();
        $periode = Carbon::parse($payroll->date, $activeTimezone->timezone);

        return [
            'id' => $payroll->id,
            'date' => $payroll->date->format('Y-m-d'),
            'periode' => $periode->locale('id')->isoFormat('MMMM YYYY'),
            'base_salary' => (float) $payroll->base_salary,
            'overtime_pay' => (float) $payroll->overtime_pay,
            'deductions' => (float) $payroll->deductions,
            'bonus' => (float) $payroll->bonus,
            'total_hours' => (int) $payroll->total_hours,
            'total_salary' => (float) $total,
            'total_salary_formatted' => 'Rp ' . number_format($total, 0, ',', '.'),
            'notes' => $payroll->notes,
        ];
    }
}
