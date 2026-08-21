<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\ProductVariant;
use App\Models\Sale;
use App\Models\TimezoneSetting;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /** Panjang jendela tren, dalam hari. */
    private const RENTANG_TREN = 14;

    public function index(Request $request)
    {
        // Timezone dibaca dari database, bukan config — lihat CLAUDE.md.
        // now() polos akan salah hari untuk deployment WITA/WIT.
        $tz = TimezoneSetting::getActive()->timezone;
        $sekarang = Carbon::now($tz);
        $hariIni = $sekarang->toDateString();

        $penjualanHariIni = Sale::where('status', 'completed')
            ->whereDate('created_at', $hariIni)
            ->get(['id', 'total_amount', 'payment_method', 'created_at', 'user_id']);

        $omzetHariIni = (float) $penjualanHariIni->sum('total_amount');
        $jumlahTransaksi = $penjualanHariIni->count();

        return view('dashboard.Dashboard', [
            'omzetHariIni' => $omzetHariIni,
            'jumlahTransaksi' => $jumlahTransaksi,
            'rataTransaksi' => $jumlahTransaksi ? $omzetHariIni / $jumlahTransaksi : 0.0,
            'tren' => $this->tren($sekarang),
            'peringkatKasir' => $this->peringkatKasir($hariIni),
            'stokKritis' => $this->stokKritis(),
            'absensi' => $this->absensi($hariIni),
            'aktivitas' => $this->aktivitas($penjualanHariIni, $tz),
        ]);
    }

    /**
     * Omzet per hari untuk RENTANG_TREN hari terakhir.
     *
     * Hari tanpa transaksi tetap dikembalikan sebagai nol — kalau dilewati,
     * garis trennya akan memampatkan sumbu waktu dan menyesatkan.
     */
    private function tren(Carbon $sekarang): array
    {
        $mulai = $sekarang->copy()->subDays(self::RENTANG_TREN - 1)->startOfDay();

        $perHari = Sale::where('status', 'completed')
            ->where('created_at', '>=', $mulai)
            ->selectRaw('DATE(created_at) as tanggal, SUM(total_amount) as omzet, COUNT(*) as transaksi')
            ->groupBy('tanggal')
            ->pluck('omzet', 'tanggal');

        $hasil = [];

        for ($i = 0; $i < self::RENTANG_TREN; $i++) {
            $tanggal = $mulai->copy()->addDays($i);
            $kunci = $tanggal->toDateString();

            $hasil[] = [
                'tanggal' => $kunci,
                'label' => $tanggal->format('d/m'),
                'omzet' => (float) ($perHari[$kunci] ?? 0),
            ];
        }

        return $hasil;
    }

    private function peringkatKasir(string $hariIni)
    {
        return User::where('role', 'karyawan')
            ->withCount(['sales as transaksi' => fn ($q) => $q->whereDate('created_at', $hariIni)->where('status', 'completed')])
            ->withSum(['sales as omzet' => fn ($q) => $q->whereDate('created_at', $hariIni)->where('status', 'completed')], 'total_amount')
            ->get()
            ->map(fn ($u) => [
                'nama' => $u->name,
                'transaksi' => (int) $u->transaksi,
                'omzet' => (float) ($u->omzet ?? 0),
            ])
            ->sortByDesc('omzet')
            ->values();
    }

    /**
     * Stok kritis dibaca dari varian, bukan kolom cermin products.stock_quantity.
     *
     * Ini pokoknya: sebuah produk bisa total 39 unit tapi ukuran M-nya nol.
     * Membaca kolom cermin membuat kehabisan per ukuran tidak pernah terlihat —
     * padahal justru itu yang bikin pembeli pulang dengan tangan kosong.
     */
    private function stokKritis()
    {
        return ProductVariant::with(['product:id,name,code', 'size:id,code'])
            ->where('stock_quantity', '<=', 5)
            ->orderBy('stock_quantity')
            ->limit(8)
            ->get()
            ->map(fn ($v) => [
                'produk' => $v->product?->name ?? '-',
                'kode' => $v->product?->code ?? '-',
                'ukuran' => $v->size?->code ?? '?',
                'stok' => $v->stock_quantity,
            ]);
    }

    private function absensi(string $hariIni): array
    {
        $hadir = Attendance::whereDate('date', $hariIni)->get(['check_in', 'check_out', 'is_late']);

        return [
            'total_karyawan' => User::where('role', 'karyawan')->count(),
            'hadir' => $hadir->whereNotNull('check_in')->count(),
            'pulang' => $hadir->whereNotNull('check_out')->count(),
            'terlambat' => $hadir->where('is_late', true)->count(),
        ];
    }

    private function aktivitas($penjualan, string $tz)
    {
        return $penjualan->sortByDesc('created_at')
            ->take(6)
            ->map(fn ($s) => [
                'judul' => 'Transaksi ' . $this->rupiah((float) $s->total_amount),
                'keterangan' => $s->formatted_payment_method,
                'waktu' => Carbon::parse($s->created_at)->timezone($tz)->format('H:i'),
            ])
            ->values();
    }

    private function rupiah(float $n): string
    {
        return 'Rp ' . number_format($n, 0, ',', '.');
    }
}
