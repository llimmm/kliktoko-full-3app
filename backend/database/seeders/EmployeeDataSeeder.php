<?php

namespace Database\Seeders;

use App\Models\Attendance;
use App\Models\Leave;
use App\Models\Payroll;
use App\Models\Shift;
use App\Models\TimezoneSetting;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

/**
 * Data absensi, cuti, dan slip gaji untuk app employee.
 *
 * Ketiga tabel ini sudah ada sejak awal tapi selalu kosong, sehingga layar
 * riwayat di app tidak pernah bisa diuji dengan data sungguhan.
 *
 * Seluruhnya memakai firstOrCreate dan nilai yang ditetapkan (bukan acak),
 * jadi aman dijalankan berulang di atas database yang sudah terisi:
 *
 *     php artisan db:seed --class=EmployeeDataSeeder
 *
 * Itu sebabnya dipisah dari DatabaseSeeder — menjalankan seeder utama akan
 * ikut memanggil SalesSeeder yang memakai Sale::create dan menggandakan
 * riwayat penjualan setiap kali dijalankan.
 */
class EmployeeDataSeeder extends Seeder
{
    public function run(): void
    {
        $this->attendances();
        $this->leaves();
        $this->payrolls();
    }

    /**
     * Riwayat absensi ~3 minggu terakhir untuk tiap karyawan.
     *
     * Sebagian sengaja terlambat supaya penanda "Terlambat" di app punya isi,
     * dan hari Minggu dilewati supaya polanya terlihat wajar. Satu baris
     * terakhir dibiarkan tanpa check_out — itu keadaan "masih di dalam shift"
     * yang dipakai app untuk menampilkan tombol pulang.
     */
    private function attendances(): void
    {
        $tz = TimezoneSetting::getActive()->timezone;
        $hariIni = Carbon::now($tz)->startOfDay();

        $shiftPagi = Shift::where('name', 'Shift Pagi')->first();
        $shiftSore = Shift::where('name', 'Shift Sore')->first();

        if (!$shiftPagi || !$shiftSore) {
            return;
        }

        $karyawan = User::where('role', 'karyawan')->orderBy('id')->get();

        foreach ($karyawan as $indeks => $user) {
            for ($mundur = 21; $mundur >= 1; $mundur--) {
                $tanggal = $hariIni->copy()->subDays($mundur);

                // Toko tutup hari Minggu.
                if ($tanggal->isSunday()) {
                    continue;
                }

                // Karyawan bergantian shift per minggu.
                $shift = (($tanggal->weekOfYear + $indeks) % 2 === 0) ? $shiftPagi : $shiftSore;

                // Pola terlambat yang tetap, bukan acak: hasil seed harus sama
                // setiap kali supaya tampilan bisa dibandingkan antar-jalan.
                $terlambat = (($mundur + $indeks) % 7 === 0);

                $mulai = Carbon::parse(
                    $tanggal->format('Y-m-d') . ' ' . $shift->start_time->format('H:i:s'),
                    $tz
                );

                $checkIn = $terlambat
                    ? $mulai->copy()->addMinutes(20 + ($mundur % 15))
                    : $mulai->copy()->subMinutes(3 + ($mundur % 10));

                $selesai = Carbon::parse(
                    $tanggal->format('Y-m-d') . ' ' . $shift->end_time->format('H:i:s'),
                    $tz
                );

                Attendance::firstOrCreate(
                    [
                        'user_id' => $user->id,
                        'date' => $tanggal->format('Y-m-d'),
                    ],
                    [
                        'shift_id' => $shift->id,
                        'check_in' => $checkIn,
                        'check_out' => $selesai->copy()->addMinutes($mundur % 12),
                        'is_late' => $terlambat,
                    ],
                );
            }
        }
    }

    /**
     * Pengajuan cuti dengan ketiga status terpakai.
     *
     * Layar cuti menampilkan status sebagai chip berwarna; kalau semuanya
     * "menunggu", tiga cabang warnanya tidak pernah terlihat saat diuji.
     */
    private function leaves(): void
    {
        $tz = TimezoneSetting::getActive()->timezone;
        $hariIni = Carbon::now($tz)->startOfDay();

        $pengajuan = [
            ['nadia', -12, Leave::STATUS_APPROVED, 'Acara keluarga di luar kota'],
            ['nadia', -5,  Leave::STATUS_REJECTED, 'Izin mendadak, tidak ada pengganti shift'],
            ['nadia', 4,   Leave::STATUS_PENDING,  'Kontrol ke dokter'],
            ['bagas', -8,  Leave::STATUS_APPROVED, 'Menghadiri wisuda adik'],
            ['bagas', 6,   Leave::STATUS_PENDING,  'Keperluan keluarga'],
            ['rizky', -3,  Leave::STATUS_APPROVED, 'Sakit demam'],
            ['sari',  9,   Leave::STATUS_PENDING,  'Cuti tahunan'],
        ];

        foreach ($pengajuan as [$nama, $geser, $status, $alasan]) {
            $user = User::where('name', $nama)->first();
            if (!$user) {
                continue;
            }

            Leave::firstOrCreate(
                [
                    'user_id' => $user->id,
                    'date' => $hariIni->copy()->addDays($geser)->format('Y-m-d'),
                ],
                [
                    'status' => $status,
                    'reason' => $alasan,
                ],
            );
        }
    }

    /**
     * Slip gaji tiga bulan terakhir untuk tiap karyawan.
     *
     * Tanggalnya ditetapkan di hari pertama bulan, karena tabel payrolls hanya
     * punya kolom `date` — tidak ada kolom periode tersendiri, jadi konvensi
     * "tanggal 1 mewakili bulan itu" ditetapkan di sini.
     */
    private function payrolls(): void
    {
        $tz = TimezoneSetting::getActive()->timezone;
        $awalBulanIni = Carbon::now($tz)->startOfMonth();

        $karyawan = User::where('role', 'karyawan')->orderBy('id')->get();

        foreach ($karyawan as $indeks => $user) {
            for ($mundur = 2; $mundur >= 0; $mundur--) {
                $periode = $awalBulanIni->copy()->subMonths($mundur);

                // Nilai tetap, bukan acak, supaya angka di layar bisa
                // dicocokkan dengan baris database saat verifikasi.
                $jam = 160 + (($indeks + $mundur) % 5) * 8;
                $lembur = (($indeks + $mundur) % 3) * 150000;
                $potongan = (($indeks + $mundur) % 4) * 50000;
                $bonus = $mundur === 0 ? 0 : (($indeks % 2) * 200000);

                Payroll::firstOrCreate(
                    [
                        'user_id' => $user->id,
                        'date' => $periode->format('Y-m-d'),
                    ],
                    [
                        'base_salary' => 2_400_000,
                        'overtime_pay' => $lembur,
                        'deductions' => $potongan,
                        'bonus' => $bonus,
                        'total_hours' => $jam,
                        'notes' => $mundur === 0
                            ? 'Slip berjalan, dapat berubah sampai akhir bulan'
                            : null,
                    ],
                );
            }
        }
    }
}
