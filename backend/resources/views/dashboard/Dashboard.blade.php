<x-admin-layout>
    <x-slot name="title">Dashboard</x-slot>

    <div class="page-header">
        <h1 class="page-title">Halo, {{ Auth::user()->name }}</h1>
        <p class="page-subtitle">Ringkasan aktivitas toko hari ini</p>
    </div>

    {{-- Hero figure: satu-satunya angka sebesar ini di halaman. --}}
    <section class="dash-hero">
        <div>
            <div class="dash-hero-label">Omzet hari ini</div>
            <div class="dash-hero-value">Rp {{ number_format($omzetHariIni, 0, ',', '.') }}</div>
            <div class="dash-hero-meta">
                {{ $jumlahTransaksi }} transaksi &middot;
                rata-rata Rp {{ number_format($rataTransaksi, 0, ',', '.') }}
            </div>
        </div>

        <div class="dash-quick">
            <a href="{{ route('products.create') }}" class="dash-quick-btn"><i class="bi bi-plus-lg"></i> Produk</a>
            <a href="{{ route('products.restock') }}" class="dash-quick-btn"><i class="bi bi-box-arrow-in-down"></i> Restock</a>
            <a href="{{ route('sales-data.index') }}" class="dash-quick-btn"><i class="bi bi-receipt"></i> Penjualan</a>
        </div>
    </section>

    <section class="dash-kpi">
        <div class="dash-kpi-item">
            <div class="dash-kpi-label">Karyawan hadir</div>
            <div class="dash-kpi-value">{{ $absensi['hadir'] }}<span class="dash-kpi-of">/{{ $absensi['total_karyawan'] }}</span></div>
        </div>
        <div class="dash-kpi-item">
            <div class="dash-kpi-label">Sudah pulang</div>
            <div class="dash-kpi-value">{{ $absensi['pulang'] }}</div>
        </div>
        <div class="dash-kpi-item">
            <div class="dash-kpi-label">Terlambat</div>
            <div class="dash-kpi-value {{ $absensi['terlambat'] > 0 ? 'is-warning' : '' }}">{{ $absensi['terlambat'] }}</div>
        </div>
        <div class="dash-kpi-item">
            <div class="dash-kpi-label">Ukuran stok kritis</div>
            <div class="dash-kpi-value {{ $stokKritis->count() > 0 ? 'is-danger' : '' }}">{{ $stokKritis->count() }}</div>
        </div>
    </section>

    <div class="dash-grid">
        {{-- Tren omzet: satu seri, jadi tanpa legend — judulnya sudah menamai. --}}
        <section class="card dash-card">
            <div class="dash-card-head">
                <h2 class="dash-card-title">Omzet 14 hari terakhir</h2>
            </div>

            @php
                $nilai = collect($tren)->pluck('omzet');
                $puncak = max($nilai->max(), 1);
                // Dibulatkan ke atas ke kelipatan rapi supaya tick sumbu enak dibaca.
                $langkah = max(10 ** max(0, strlen((string) (int) $puncak) - 2), 1) * 5;
                $atas = (int) (ceil($puncak / $langkah) * $langkah);

                $w = 680; $h = 150; $padKiri = 8; $padBawah = 22;
                $plotW = $w - $padKiri; $plotH = $h - $padBawah;
                $n = count($tren);
                $titik = [];
                foreach ($tren as $i => $t) {
                    $x = $padKiri + ($n > 1 ? $i * ($plotW / ($n - 1)) : $plotW / 2);
                    $y = $plotH - ($atas > 0 ? ($t['omzet'] / $atas) * $plotH : 0);
                    $titik[] = ['x' => round($x, 1), 'y' => round($y, 1)] + $t;
                }
                $garis = collect($titik)->map(fn ($p) => "{$p['x']},{$p['y']}")->implode(' ');
                $area = "{$padKiri},{$plotH} " . $garis . " " . end($titik)['x'] . ",{$plotH}";
                $akhir = end($titik);
            @endphp

            <svg class="dash-chart" viewBox="0 0 {{ $w }} {{ $h }}" role="img"
                 aria-label="Grafik garis omzet harian selama 14 hari terakhir">
                <title>Omzet 14 hari terakhir</title>

                {{-- Gridline hairline, resesif --}}
                @foreach ([0, 0.5, 1] as $f)
                    <line x1="{{ $padKiri }}" y1="{{ round($plotH * $f, 1) }}"
                          x2="{{ $w }}" y2="{{ round($plotH * $f, 1) }}"
                          stroke="var(--neutral-200)" stroke-width="1" />
                @endforeach

                {{-- Wash area ~10% --}}
                <polygon points="{{ $area }}" fill="var(--violet-600)" fill-opacity="0.1" />
                <polyline points="{{ $garis }}" fill="none" stroke="var(--violet-600)"
                          stroke-width="2" stroke-linejoin="round" stroke-linecap="round" />

                {{-- Titik interaktif: <title> bawaan SVG memberi tooltip tanpa JS --}}
                @foreach ($titik as $p)
                    <circle cx="{{ $p['x'] }}" cy="{{ $p['y'] }}" r="{{ $loop->last ? 5 : 9 }}"
                            fill="{{ $loop->last ? 'var(--violet-600)' : 'transparent' }}"
                            stroke="{{ $loop->last ? 'var(--neutral-0)' : 'none' }}" stroke-width="2">
                        <title>{{ $p['label'] }} — Rp {{ number_format($p['omzet'], 0, ',', '.') }}</title>
                    </circle>
                @endforeach

                {{-- Tidak ada label ujung: nilainya sama persis dengan hero figure
                     di atas, dan menaruhnya di sini menabrak garisnya sendiri.
                     Nilai per titik tetap terbaca lewat <title> saat hover. --}}
                @foreach ($titik as $i => $p)
                    @if ($i % 3 === 0 || $loop->last)
                        <text x="{{ $p['x'] }}" y="{{ $h - 6 }}" text-anchor="middle"
                              class="dash-chart-tick">{{ $p['label'] }}</text>
                    @endif
                @endforeach
            </svg>
        </section>

        {{-- Peringkat kasir: satu seri (omzet), jadi satu hue, bukan kategorikal. --}}
        <section class="card dash-card">
            <div class="dash-card-head">
                <h2 class="dash-card-title">Kasir hari ini</h2>
            </div>

            @php $tertinggi = max($peringkatKasir->max('omzet') ?? 0, 1); @endphp

            @forelse ($peringkatKasir as $k)
                <div class="dash-rank">
                    <div class="dash-rank-head">
                        <span class="dash-rank-name">{{ $k['nama'] }}</span>
                        <span class="dash-rank-value">Rp {{ number_format($k['omzet'], 0, ',', '.') }}</span>
                    </div>
                    <div class="dash-rank-track">
                        {{-- Omzet nol berarti tanpa bar sama sekali; lebar minimum
                             akan membuat kasir yang belum menjual apa pun tampak
                             seolah sudah menjual sesuatu. --}}
                        <div class="dash-rank-bar" style="width: {{ $k['omzet'] > 0 ? max(2, round($k['omzet'] / $tertinggi * 100)) : 0 }}%"></div>
                    </div>
                    <div class="dash-rank-meta">{{ $k['transaksi'] }} transaksi</div>
                </div>
            @empty
                <p class="text-secondary mb-0">Belum ada karyawan.</p>
            @endforelse
        </section>

        {{-- Stok dibaca per ukuran, bukan total produk. --}}
        <section class="card dash-card">
            <div class="dash-card-head">
                <h2 class="dash-card-title">Stok kritis per ukuran</h2>
                <a href="{{ route('products.restock') }}" class="dash-card-link">Restock</a>
            </div>

            @forelse ($stokKritis as $s)
                <div class="dash-stock">
                    <div>
                        <div class="dash-stock-name">{{ $s['produk'] }}</div>
                        <div class="dash-stock-meta">{{ $s['kode'] }} &middot; ukuran {{ $s['ukuran'] }}</div>
                    </div>
                    @if ($s['stok'] === 0)
                        <span class="dash-tag is-danger"><i class="bi bi-x-circle"></i> Habis</span>
                    @else
                        <span class="dash-tag is-warning"><i class="bi bi-exclamation-triangle"></i> Sisa {{ $s['stok'] }}</span>
                    @endif
                </div>
            @empty
                <p class="text-secondary mb-0">Semua ukuran stoknya aman.</p>
            @endforelse
        </section>

        <section class="card dash-card">
            <div class="dash-card-head">
                <h2 class="dash-card-title">Transaksi terakhir</h2>
                <a href="{{ route('sales-data.index') }}" class="dash-card-link">Semua</a>
            </div>

            @forelse ($aktivitas as $a)
                <div class="dash-activity">
                    <div>
                        <div class="dash-activity-title">{{ $a['judul'] }}</div>
                        <div class="dash-activity-meta">{{ $a['keterangan'] }}</div>
                    </div>
                    <span class="dash-activity-time">{{ $a['waktu'] }}</span>
                </div>
            @empty
                <p class="text-secondary mb-0">Belum ada transaksi hari ini.</p>
            @endforelse
        </section>
    </div>
</x-admin-layout>
