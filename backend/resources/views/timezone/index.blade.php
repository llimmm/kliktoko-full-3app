<x-admin-layout title="Zona Waktu">
    @push('styles')
    <style>
        /*
         * Hanya jam besar dan kisi pilihan yang khas halaman ini.
         * Kartu, tabel, badge, dan empty state datang dari admin.css.
         */
        .tz-hero {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 1.5rem;
            padding: 2rem;
            margin-bottom: 2rem;
            border-left: 4px solid var(--violet-600);
        }

        .tz-clock {
            font-family: 'JetBrains Mono', monospace;
            font-size: clamp(2.5rem, 7vw, 3.5rem);
            font-weight: 600;
            line-height: 1.1;
            color: var(--text-primary);
            font-variant-numeric: tabular-nums;
        }

        .tz-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }

        .tz-option {
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            padding: 1.25rem;
        }

        /* Zona aktif menyetir seluruh perhitungan shift & absensi, jadi tandanya
           tegas — bukan hanya badge kecil di pojok. */
        .tz-option.is-active {
            border-color: var(--violet-600);
            box-shadow: inset 0 0 0 1px var(--violet-600);
            background: var(--violet-50);
        }

        .tz-option-name {
            font-size: 1.125rem;
            font-weight: 600;
            color: var(--text-primary);
        }

        .tz-option-desc {
            flex: 1;
            margin: 0;
            font-size: 0.875rem;
            color: var(--text-secondary);
        }
    </style>
    @endpush

    @php $tz = $activeTimezone->timezone; @endphp

    <div class="page-header">
        <h1 class="page-title">Zona Waktu</h1>
        <p class="page-subtitle">Zona aktif dipakai seluruh perhitungan shift, absensi, dan check-in — di panel admin maupun aplikasi mobile.</p>
    </div>

    <div class="card tz-hero">
        <div>
            <div class="text-secondary small text-uppercase">Zona waktu aktif</div>
            <div class="tz-clock" id="currentTime">{{ now($tz)->format('H:i:s') }}</div>
            <div class="text-secondary" id="currentDate">{{ now($tz)->locale('id')->translatedFormat('l, j F Y') }}</div>
        </div>
        <div>
            <div class="d-flex align-items-center gap-2 mb-2">
                <span class="fs-3 fw-bold">{{ $activeTimezone->timezone_name }}</span>
                <span class="status-badge active">Aktif</span>
            </div>
            <div class="d-flex flex-wrap gap-2">
                <span class="code-badge">{{ $tz }}</span>
                <span class="code-badge">UTC{{ $activeTimezone->utc_offset >= 0 ? '+' : '' }}{{ $activeTimezone->utc_offset }}</span>
            </div>
        </div>
    </div>

    <h5 class="section-title mb-3">Ganti Zona Waktu</h5>

    <div class="tz-grid">
        @foreach($timezoneOptions as $option)
            @php $isActive = $tz === $option['timezone']; @endphp
            <div class="card tz-option {{ $isActive ? 'is-active' : '' }}">
                <div class="d-flex align-items-start justify-content-between gap-2">
                    <span class="tz-option-name">{{ $option['timezone_name'] }}</span>
                    @if($isActive)
                        <span class="status-badge active">Aktif</span>
                    @endif
                </div>
                <p class="tz-option-desc">{{ $option['description'] }}</p>
                <div class="d-flex flex-wrap gap-2">
                    <span class="code-badge">{{ $option['timezone'] }}</span>
                    <span class="code-badge">UTC+{{ $option['utc_offset'] }}</span>
                </div>
                @unless($isActive)
                    <form method="POST" action="{{ route('timezone.update.form') }}">
                        @csrf
                        <input type="hidden" name="timezone" value="{{ $option['timezone'] }}">
                        <input type="hidden" name="timezone_name" value="{{ $option['timezone_name'] }}">
                        <input type="hidden" name="utc_offset" value="{{ $option['utc_offset'] }}">
                        <button type="submit" class="btn btn-primary w-100 justify-content-center">
                            <i class="bi bi-arrow-repeat"></i>
                            Gunakan {{ $option['timezone_name'] }}
                        </button>
                    </form>
                @endunless
            </div>
        @endforeach
    </div>

    <h5 class="section-title mb-3">Riwayat Perubahan</h5>

    <div class="modern-table">
        <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr>
                        <th>Zona</th>
                        <th>Identifier</th>
                        <th>Offset</th>
                        <th>Status</th>
                        <th>Terakhir Diubah</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($timezoneSettings as $setting)
                        <tr>
                            <td class="fw-semibold">{{ $setting->timezone_name }}</td>
                            <td><span class="code-badge">{{ $setting->timezone }}</span></td>
                            <td>UTC{{ $setting->utc_offset >= 0 ? '+' : '' }}{{ $setting->utc_offset }}</td>
                            <td>
                                <span class="status-badge {{ $setting->is_active ? 'active' : 'inactive' }}">
                                    {{ $setting->is_active ? 'Aktif' : 'Tidak Aktif' }}
                                </span>
                            </td>
                            <td>{{ $setting->updated_at->format('d M Y, H:i') }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5">
                                <div class="empty-state">
                                    <i class="bi bi-clock-history empty-state-icon"></i>
                                    <div class="empty-state-title">Belum ada riwayat</div>
                                    <div class="empty-state-description">Perubahan zona waktu akan tercatat di sini</div>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    @push('scripts')
    <script>
        // Jam halaman ini mengikuti zona aktif dari database, bukan jam browser.
        // Waktu pakai en-GB supaya pemisahnya titik dua seperti render server;
        // id-ID memakai titik ("07.30.00") dan bikin tampilan melompat.
        (function () {
            const zone = @json($tz);
            const timeFormat = new Intl.DateTimeFormat('en-GB', {
                timeZone: zone, hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false
            });
            const dateFormat = new Intl.DateTimeFormat('id-ID', {
                timeZone: zone, weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
            });
            const timeEl = document.getElementById('currentTime');
            const dateEl = document.getElementById('currentDate');

            setInterval(function () {
                const now = new Date();
                timeEl.textContent = timeFormat.format(now);
                dateEl.textContent = dateFormat.format(now);
            }, 1000);
        })();
    </script>
    @endpush
</x-admin-layout>
