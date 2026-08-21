<x-admin-layout>
    <x-slot name="title">Detail Shift - {{ $user->name }}</x-slot>

    @php
        $present = $attendances->whereNotNull('check_in');
        $presentCount = $present->count();
        $onTimeCount = $present->where('is_late', false)->count();
        $lateCount = $present->where('is_late', true)->count();
        $total = $attendances->count();
        $pct = fn ($part, $whole) => $whole > 0 ? round(($part / $whole) * 100, 1) . '%' : '—';
    @endphp

    <div class="page-header d-flex justify-content-between align-items-start gap-3 flex-wrap">
        <div class="d-flex align-items-start gap-3">
            <a href="{{ route('shifts.index') }}#summary" class="btn btn-outline-secondary" onclick="localStorage.setItem('activeTab', 'summary')">
                <i class="bi bi-arrow-left"></i> Kembali
            </a>
            <div>
                <h1 class="page-title">Detail Shift</h1>
                <p class="page-subtitle">Riwayat kehadiran {{ $user->name }}</p>
            </div>
        </div>
        <input type="month" class="form-control w-auto" id="monthFilter" value="{{ $month }}" aria-label="Pilih bulan">
    </div>

    <div class="card mb-4">
        <div class="card-body d-flex align-items-center gap-3 flex-wrap">
            <div class="user-avatar">
                <img src="https://ui-avatars.com/api/?name={{ urlencode($user->name) }}&background=random" alt="">
            </div>
            <div class="user-info">
                <div class="user-name fs-5">{{ $user->name }}</div>
                <div class="text-secondary small">ID: {{ $user->id }} &middot; {{ $user->email ?? '-' }}</div>
            </div>
            <div class="d-flex gap-4 ms-auto">
                <div class="stat-item">
                    <span class="dash-kpi-value">{{ $monthlyStats->total_shifts }}</span>
                    <span class="dash-kpi-label">Total Shift</span>
                </div>
                <div class="stat-item">
                    <span class="dash-kpi-value">{{ $monthlyStats->total_hours }}</span>
                    <span class="dash-kpi-label">Jam Kerja</span>
                </div>
            </div>
        </div>
    </div>

    <div class="dash-kpi">
        <div class="dash-kpi-item">
            <div class="dash-kpi-label"><i class="bi bi-sun"></i> Shift Pagi</div>
            <div class="dash-kpi-value">
                {{ $monthlyStats->shift_1_count }}
                <span class="dash-kpi-of">{{ $pct($monthlyStats->shift_1_count, $monthlyStats->total_shifts) }}</span>
            </div>
        </div>
        <div class="dash-kpi-item">
            <div class="dash-kpi-label"><i class="bi bi-moon"></i> Shift Sore</div>
            <div class="dash-kpi-value">
                {{ $monthlyStats->shift_2_count }}
                <span class="dash-kpi-of">{{ $pct($monthlyStats->shift_2_count, $monthlyStats->total_shifts) }}</span>
            </div>
        </div>
        <div class="dash-kpi-item">
            <div class="dash-kpi-label"><i class="bi bi-check-circle"></i> Kehadiran</div>
            <div class="dash-kpi-value">
                {{ $presentCount }}
                <span class="dash-kpi-of">{{ $pct($presentCount, $total) }}</span>
            </div>
        </div>
        <div class="dash-kpi-item">
            <div class="dash-kpi-label"><i class="bi bi-clock"></i> Terlambat</div>
            <div class="dash-kpi-value {{ $lateCount > 0 ? 'is-warning' : '' }}">
                {{ $lateCount }}
                <span class="dash-kpi-of">{{ $pct($lateCount, $presentCount) }}</span>
            </div>
        </div>
        <div class="dash-kpi-item">
            <div class="dash-kpi-label"><i class="bi bi-calendar-x"></i> Cuti</div>
            <div class="dash-kpi-value">{{ $monthlyStats->leave_days }}</div>
        </div>
    </div>

    <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap mb-3">
        <h5 class="mb-0">Riwayat Shift</h5>
        <div class="d-flex gap-2 flex-wrap" role="group" aria-label="Saring riwayat">
            <button type="button" class="filter-btn is-active" data-filter="all">Semua ({{ $total }})</button>
            <button type="button" class="filter-btn" data-filter="present">Tepat Waktu ({{ $onTimeCount }})</button>
            <button type="button" class="filter-btn" data-filter="late">Terlambat ({{ $lateCount }})</button>
            <button type="button" class="filter-btn" data-filter="absent">Tidak Hadir ({{ $total - $presentCount }})</button>
        </div>
    </div>

    @if($attendances->isEmpty())
        <div class="card empty-state">
            <i class="bi bi-calendar-x empty-state-icon"></i>
            <div class="empty-state-title">Tidak ada data shift</div>
            <div class="empty-state-description">Belum ada riwayat kehadiran untuk periode ini.</div>
        </div>
    @else
        <div class="modern-table">
            <div class="table-responsive">
                <table class="table align-middle">
                    <thead>
                        <tr>
                            <th>Tanggal</th>
                            <th>Shift</th>
                            <th>Check-in</th>
                            <th>Check-out</th>
                            <th>Durasi</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($attendances as $attendance)
                            {{-- check_in / check_out boleh NULL; setiap pemakaian dijaga. --}}
                            <tr class="attendance-row" data-status="{{ $attendance->check_in ? ($attendance->is_late ? 'late' : 'present') : 'absent' }}">
                                <td>
                                    <div class="user-name">{{ $attendance->date?->format('d M Y') ?? '—' }}</div>
                                    <div class="text-secondary small text-capitalize">{{ $attendance->date?->isoFormat('dddd') }}</div>
                                </td>
                                <td>
                                    <span class="code-badge">
                                        <i class="bi {{ $attendance->shift_id == 1 ? 'bi-sun' : 'bi-moon' }}"></i>
                                        {{ $attendance->shift?->name ?? 'Shift ' . $attendance->shift_id }}
                                    </span>
                                </td>
                                <td>{{ $attendance->check_in ? \Carbon\Carbon::parse($attendance->check_in)->format('H:i') : '—' }}</td>
                                <td>{{ $attendance->check_out ? \Carbon\Carbon::parse($attendance->check_out)->format('H:i') : '—' }}</td>
                                <td>{{ $attendance->duration ?? '—' }}</td>
                                <td>
                                    {{-- Ikon + teks, bukan warna saja. --}}
                                    @if(!$attendance->check_in)
                                        <span class="status-badge inactive"><i class="bi bi-x-circle"></i> Tidak Hadir</span>
                                    @elseif($attendance->is_late)
                                        <span class="status-badge pending"><i class="bi bi-exclamation-circle"></i> Terlambat</span>
                                    @else
                                        <span class="status-badge active"><i class="bi bi-check-circle"></i> Tepat Waktu</span>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
        <p class="pagination-info mt-2 mb-0" id="filterEmptyHint" hidden>Tidak ada shift yang cocok dengan filter ini.</p>
    @endif

    <style>
        /*
         * Halaman ini memakai .card, .modern-table, .status-badge, .code-badge,
         * .dash-kpi*, .user-avatar, .empty-state*, dan .filter-btn dari admin.css.
         * Yang tersisa di sini hanya keadaan aktif tombol filter — admin.css
         * mendefinisikan .filter-btn tanpa state terpilih.
         */
        .filter-btn.is-active {
            background: var(--violet-600);
            border-color: var(--violet-600);
            color: var(--neutral-0);
        }

        .filter-btn.is-active:hover {
            background: var(--violet-700);
            border-color: var(--violet-700);
            color: var(--neutral-0);
        }

        .stat-item .dash-kpi-value { display: block; font-size: 1.25rem; }
    </style>

    <script>
        document.getElementById('monthFilter').addEventListener('change', function () {
            window.location.href = '{{ route('shifts.detail', $user->id) }}?month=' + this.value;
        });

        const attendanceRows = document.querySelectorAll('.attendance-row');
        const filterHint = document.getElementById('filterEmptyHint');

        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', function () {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('is-active'));
                this.classList.add('is-active');

                const filter = this.dataset.filter;
                let visible = 0;
                attendanceRows.forEach(row => {
                    const show = filter === 'all' || row.dataset.status === filter;
                    row.hidden = !show;
                    if (show) visible++;
                });
                if (filterHint) filterHint.hidden = visible > 0;
            });
        });
    </script>
</x-admin-layout>
