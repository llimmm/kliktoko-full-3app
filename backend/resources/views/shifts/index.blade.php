<x-admin-layout>
    <x-slot name="title">Manajemen Shift</x-slot>

    @php
        // Timezone selalu dari baris aktif di database, bukan config/app.php.
        $tz = \App\Models\TimezoneSetting::getActive()->timezone;
        $now = \Carbon\Carbon::now($tz);
        $selectedMonth = request('month', $now->format('Y-m'));
        $activeTab = session('activeTab');
    @endphp

    <div class="page-header d-flex justify-content-between align-items-start gap-3 flex-wrap">
        <div>
            <h1 class="page-title">Manajemen Shift</h1>
            <p class="page-subtitle">Shift berjalan, ringkasan kehadiran bulanan, dan jam kerja.</p>
        </div>
        <div class="d-flex align-items-center gap-2">
            <span class="code-badge"><i class="bi bi-clock"></i> {{ $now->format('H:i') }} {{ $now->format('T') }}</span>
            <input type="month" class="form-control w-auto" id="monthFilter" value="{{ $selectedMonth }}" aria-label="Pilih bulan">
        </div>
    </div>

    <ul class="nav nav-pills gap-2 mb-4" id="shiftsTab" role="tablist">
        <li class="nav-item" role="presentation">
            <button class="nav-link active" id="active-tab" data-bs-toggle="tab" data-bs-target="#active" type="button" role="tab" aria-controls="active" aria-selected="true">
                <i class="bi bi-clock-history"></i> Shift Aktif
                <span class="badge bg-secondary ms-1">{{ $activeUsers->count() }}</span>
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" id="summary-tab" data-bs-toggle="tab" data-bs-target="#summary" type="button" role="tab" aria-controls="summary" aria-selected="false">
                <i class="bi bi-calendar2-week"></i> Ringkasan Bulanan
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" id="settings-tab" data-bs-toggle="tab" data-bs-target="#settings" type="button" role="tab" aria-controls="settings" aria-selected="false">
                <i class="bi bi-gear"></i> Pengaturan Shift
            </button>
        </li>
    </ul>

    <div class="tab-content" id="shiftsTabContent">

        {{-- ================= Shift Aktif ================= --}}
        <div class="tab-pane fade show active" id="active" role="tabpanel" aria-labelledby="active-tab">
            @if($activeUsers->isEmpty())
                <div class="card empty-state">
                    <i class="bi bi-clock-history empty-state-icon"></i>
                    <div class="empty-state-title">Tidak ada shift aktif</div>
                    <div class="empty-state-description">Belum ada karyawan yang sedang menjalani shift saat ini.</div>
                </div>
            @else
                <div class="row g-3" id="activeShifts">
                    @foreach($activeUsers as $user)
                        @php
                            $attendance = $user->attendances->first();
                            // check_in bisa NULL pada baris absensi yang belum lengkap.
                            $checkIn = $attendance?->check_in ? \Carbon\Carbon::parse($attendance->check_in) : null;
                            $duration = null;
                            if ($checkIn) {
                                $totalMinutes = abs($now->diffInMinutes($checkIn));
                                $duration = intdiv($totalMinutes, 60) . ' jam ' . $totalMinutes % 60 . ' menit';
                            }
                        @endphp
                        <div class="col-12 col-sm-6 col-xl-3">
                            <div class="card h-100 overflow-hidden" data-name="{{ strtolower($user->name) }}">
                                @if($attendance?->check_in_photo)
                                    <img src="{{ asset('storage/' . $attendance->check_in_photo) }}" class="shift-photo" alt="Foto check-in {{ $user->name }}">
                                @else
                                    <div class="shift-photo d-flex align-items-center justify-content-center bg-body-secondary text-secondary">
                                        <i class="bi bi-person-circle fs-1"></i>
                                    </div>
                                @endif
                                <div class="card-body p-3">
                                    <div class="user-name">{{ $user->name }}</div>
                                    <div class="text-secondary small">
                                        <i class="bi {{ $attendance?->shift_id == 1 ? 'bi-sun' : 'bi-moon' }}"></i>
                                        {{ $attendance?->shift?->name ?? 'Shift ' . ($attendance?->shift_id ?? '-') }}
                                    </div>
                                    <div class="text-secondary small">
                                        <i class="bi bi-box-arrow-in-right"></i> Masuk {{ $checkIn?->format('H:i') ?? '—' }}
                                        <span class="mx-1">&middot;</span>
                                        <i class="bi bi-hourglass-split"></i> {{ $duration ?? 'Belum check-in' }}
                                    </div>
                                    <div class="mt-2">
                                        {{-- Keterlambatan selalu ikon + teks, tidak pernah warna saja. --}}
                                        @if($attendance?->is_late)
                                            <span class="status-badge pending"><i class="bi bi-exclamation-circle"></i> Terlambat</span>
                                        @else
                                            <span class="status-badge active"><i class="bi bi-check-circle"></i> Tepat Waktu</span>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
            @endif
        </div>

        {{-- ================= Ringkasan Bulanan ================= --}}
        <div class="tab-pane fade" id="summary" role="tabpanel" aria-labelledby="summary-tab">
            <div class="dash-kpi">
                <div class="dash-kpi-item">
                    <div class="dash-kpi-label">Total Karyawan</div>
                    <div class="dash-kpi-value">{{ $stats->total_employees }}</div>
                </div>
                <div class="dash-kpi-item">
                    <div class="dash-kpi-label">Total Shift</div>
                    <div class="dash-kpi-value">{{ $stats->total_shifts }}</div>
                </div>
                <div class="dash-kpi-item">
                    <div class="dash-kpi-label">Rata-rata Shift / Karyawan</div>
                    <div class="dash-kpi-value">{{ number_format($stats->avg_shifts_per_employee, 1) }}</div>
                </div>
                <div class="dash-kpi-item">
                    <div class="dash-kpi-label">Keterlambatan</div>
                    <div class="dash-kpi-value {{ ($stats->total_late_count ?? 0) > 0 ? 'is-warning' : '' }}">{{ $stats->total_late_count ?? 0 }}</div>
                </div>
            </div>

            <div class="search-filter-container">
                <div class="search-box">
                    <i class="bi bi-search search-icon"></i>
                    <input type="text" placeholder="Cari karyawan berdasarkan nama atau ID..." id="searchUser" aria-label="Cari karyawan">
                </div>
                <div class="filter-dropdown">
                    <button class="filter-btn" id="filterBtn" type="button">
                        <i class="bi bi-funnel"></i> Filter <i class="bi bi-chevron-down"></i>
                    </button>
                    <div class="filter-menu" id="filterMenu">
                        <div class="filter-item active" data-filter="all">Semua Karyawan</div>
                        <div class="filter-item" data-filter="active">Aktif</div>
                        <div class="filter-item" data-filter="inactive">Tidak Aktif</div>
                        <div class="filter-item" data-filter="late">Pernah Terlambat</div>
                    </div>
                </div>
            </div>

            @if($summaries->isEmpty())
                <div class="card empty-state">
                    <i class="bi bi-people empty-state-icon"></i>
                    <div class="empty-state-title">Tidak ada data karyawan</div>
                    <div class="empty-state-description">Belum ada karyawan dengan kehadiran pada periode ini.</div>
                </div>
            @else
                <div class="modern-table">
                    <div class="table-responsive">
                        <table class="table align-middle" id="summaryTable">
                            <thead>
                                <tr>
                                    <th>Karyawan</th>
                                    <th class="text-end">Total Shift</th>
                                    <th class="text-end">Pagi</th>
                                    <th class="text-end">Sore</th>
                                    <th class="text-end">Cuti</th>
                                    <th>Jam Kerja</th>
                                    <th>Keterlambatan</th>
                                    <th class="text-end">Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($summaries as $summary)
                                    <tr class="employee-row"
                                        data-name="{{ strtolower($summary->user->name) }}"
                                        data-id="{{ $summary->user->id }}"
                                        data-status="{{ $summary->user->is_active ? 'active' : 'inactive' }}"
                                        data-late="{{ $summary->late_count }}">
                                        <td>
                                            <div class="d-flex align-items-center gap-2">
                                                <img src="https://ui-avatars.com/api/?name={{ urlencode($summary->user->name) }}&background=random"
                                                     alt="" width="32" height="32" class="rounded-circle flex-shrink-0">
                                                <div>
                                                    <div class="user-name">{{ $summary->user->name }}</div>
                                                    <div class="text-secondary small">ID: {{ $summary->user->id }}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="text-end">{{ $summary->total_shifts }}</td>
                                        <td class="text-end">{{ $summary->shift_1_count }}</td>
                                        <td class="text-end">{{ $summary->shift_2_count }}</td>
                                        <td class="text-end">{{ $summary->leave_days }}</td>
                                        <td>{{ $summary->total_hours }}</td>
                                        <td>
                                            @if($summary->late_count > 0)
                                                <span class="dash-tag is-warning"><i class="bi bi-exclamation-circle"></i> {{ $summary->late_count }}x terlambat</span>
                                            @else
                                                <span class="text-secondary small"><i class="bi bi-check-circle"></i> Tidak pernah</span>
                                            @endif
                                        </td>
                                        <td class="text-end">
                                            <a href="{{ route('shifts.detail', $summary->user->id) }}?month={{ $selectedMonth }}" class="btn btn-sm btn-outline-primary">
                                                <i class="bi bi-eye"></i> Detail
                                            </a>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>
                <p class="pagination-info mt-2 mb-0" id="summaryEmptyHint" hidden>Tidak ada karyawan yang cocok dengan filter.</p>
            @endif
        </div>

        {{-- ================= Pengaturan Shift ================= --}}
        <div class="tab-pane fade" id="settings" role="tabpanel" aria-labelledby="settings-tab">
            <div class="modern-table">
                <div class="table-responsive">
                    <table class="table align-middle">
                        <thead>
                            <tr>
                                <th>Shift</th>
                                <th>Jam Masuk</th>
                                <th>Jam Pulang</th>
                                <th>Toleransi Keterlambatan</th>
                                <th class="text-end">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($shifts as $shift)
                                <tr>
                                    <td>
                                        <i class="bi {{ $shift->id == 1 ? 'bi-sun' : 'bi-moon' }} text-secondary"></i>
                                        <span class="user-name d-inline">{{ $shift->name }}</span>
                                    </td>
                                    <td>{{ $shift->start_time?->format('H:i') ?? '—' }}</td>
                                    <td>{{ $shift->end_time?->format('H:i') ?? '—' }}</td>
                                    <td>{{ $shift->late_tolerance }} menit</td>
                                    <td class="text-end">
                                        <button type="button" class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#editShiftModal{{ $shift->id }}">
                                            <i class="bi bi-pencil"></i> Ubah
                                        </button>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    {{-- Modal di luar tabel: <div> di dalam <tbody> bukan markup yang sah. --}}
    @foreach($shifts as $shift)
        <div class="modal fade" id="editShiftModal{{ $shift->id }}" tabindex="-1" aria-labelledby="editShiftLabel{{ $shift->id }}" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <form action="{{ route('shifts.update_times') }}" method="POST" data-shift-form>
                        @csrf
                        @method('PUT')
                        <div class="modal-header">
                            <h5 class="modal-title" id="editShiftLabel{{ $shift->id }}">Ubah {{ $shift->name }}</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Tutup"></button>
                        </div>
                        <div class="modal-body">
                            <div class="form-group">
                                <label class="form-label" for="start_time_{{ $shift->id }}">Jam mulai shift &amp; check-in</label>
                                <input type="time" class="form-control" id="start_time_{{ $shift->id }}"
                                       name="shifts[{{ $shift->id }}][start_time]"
                                       value="{{ old('shifts.' . $shift->id . '.start_time', $shift->start_time?->format('H:i')) }}" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label" for="end_time_{{ $shift->id }}">Jam selesai shift &amp; check-out</label>
                                <input type="time" class="form-control" id="end_time_{{ $shift->id }}"
                                       name="shifts[{{ $shift->id }}][end_time]"
                                       value="{{ old('shifts.' . $shift->id . '.end_time', $shift->end_time?->format('H:i')) }}" required>
                            </div>
                            <div class="form-group mb-0">
                                <label class="form-label" for="late_tolerance_{{ $shift->id }}">Toleransi keterlambatan (menit)</label>
                                <input type="number" class="form-control" id="late_tolerance_{{ $shift->id }}"
                                       name="shifts[{{ $shift->id }}][late_tolerance]"
                                       value="{{ old('shifts.' . $shift->id . '.late_tolerance', $shift->late_tolerance) }}" min="0" max="180">
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                            <button type="submit" class="btn btn-primary"><i class="bi bi-save"></i> Simpan</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    @endforeach

    <style>
        /*
         * Hanya gaya khusus halaman ini. Kartu, tabel, badge, pencarian, filter,
         * KPI, dan empty state semuanya berasal dari admin.css.
         */

        /* admin.css menata .nav-link untuk sidebar; netralkan pada tab konten. */
        #shiftsTab .nav-link { margin: 0; }
        #shiftsTab .nav-link:hover { transform: none; }
        #shiftsTab { --bs-nav-pills-link-active-bg: var(--violet-600); }

        /* Foto check-in pada kartu shift aktif. */
        .shift-photo { height: 160px; width: 100%; object-fit: cover; }
    </style>

    <script>
        document.getElementById('monthFilter').addEventListener('change', function () {
            window.location.href = '/shifts?month=' + this.value;
        });

        // ---- Ringkasan bulanan: cari + filter (keduanya menyaring baris yang sama) ----
        const summaryRows = document.querySelectorAll('.employee-row');
        const summaryHint = document.getElementById('summaryEmptyHint');
        let currentFilter = 'all';
        let currentSearch = '';

        function applySummaryFilters() {
            let visible = 0;
            summaryRows.forEach(row => {
                const matchesSearch = !currentSearch
                    || row.dataset.name.includes(currentSearch)
                    || row.dataset.id === currentSearch;
                let matchesFilter = true;
                if (currentFilter === 'active' || currentFilter === 'inactive') {
                    matchesFilter = row.dataset.status === currentFilter;
                } else if (currentFilter === 'late') {
                    matchesFilter = parseInt(row.dataset.late, 10) > 0;
                }
                const show = matchesSearch && matchesFilter;
                row.hidden = !show;
                if (show) visible++;
            });
            if (summaryHint) summaryHint.hidden = visible > 0;
        }

        const searchUser = document.getElementById('searchUser');
        if (searchUser) {
            searchUser.addEventListener('input', function () {
                currentSearch = this.value.trim().toLowerCase();
                applySummaryFilters();
            });
        }

        const filterBtn = document.getElementById('filterBtn');
        const filterMenu = document.getElementById('filterMenu');
        filterBtn.addEventListener('click', function (e) {
            e.stopPropagation();
            filterMenu.classList.toggle('show');
        });
        document.addEventListener('click', function (e) {
            if (!e.target.closest('.filter-dropdown')) filterMenu.classList.remove('show');
        });
        document.querySelectorAll('.filter-item').forEach(item => {
            item.addEventListener('click', function () {
                document.querySelectorAll('.filter-item').forEach(i => i.classList.remove('active'));
                this.classList.add('active');
                currentFilter = this.dataset.filter;
                applySummaryFilters();
                filterMenu.classList.remove('show');
            });
        });

        // ---- Pengaturan shift: jam masuk harus mendahului jam pulang ----
        document.querySelectorAll('form[data-shift-form]').forEach(form => {
            form.addEventListener('submit', function (e) {
                const start = form.querySelector('[name$="[start_time]"]').value;
                const end = form.querySelector('[name$="[end_time]"]').value;
                if (start && end && start >= end) {
                    e.preventDefault();
                    alert('Jam masuk harus lebih awal dari jam pulang.');
                }
            });
        });

        // ---- Tab yang terbuka setelah redirect / dari halaman detail ----
        document.addEventListener('DOMContentLoaded', function () {
            const target = @json($activeTab) || (window.location.hash === '#summary' ? 'summary' : null) || localStorage.getItem('activeTab');
            localStorage.removeItem('activeTab');
            const tab = target && document.getElementById(target + '-tab');
            if (tab) tab.click();
        });
    </script>
</x-admin-layout>
