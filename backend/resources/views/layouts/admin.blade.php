<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>KlikToko - {{ $title ?? 'Dashboard' }}</title>
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <link rel="shortcut icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    {{-- Satu sumber ikon saja. Dulu ada empat (jsdelivr + cdnjs + unpkg + lokal);
         salinan lokalnya rusak — CSS-nya merujuk .woff2 yang tidak ikut terbackup. --}}
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    {{-- tokens.css harus lebih dulu: seluruh variabel palet berasal dari sana. --}}
    <link href="{{ asset('css/tokens.css') }}?v={{ filemtime(public_path('css/tokens.css')) }}" rel="stylesheet">
    <link href="{{ asset('css/admin.css') }}?v={{ filemtime(public_path('css/admin.css')) }}" rel="stylesheet">
    @stack('styles')
    <style>
        /* Ensure Bootstrap Icons display properly */
        .bi {
            display: inline-block;
            font-family: "bootstrap-icons" !important;
            font-style: normal;
            font-weight: normal !important;
            font-variant: normal;
            text-transform: none;
            line-height: 1;
            vertical-align: -.125em;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }
    </style>
</head>
<body>
    <!-- Sidebar -->
    <nav class="sidebar">
        <div class="sidebar-header">
            <div class="logo-container">
                <img src="{{ asset('images/logo.png') }}" alt="KlikToko Logo" class="rounded" style="width: 40px; height: 40px;">
                <h4>KlikToko Admin</h4>
            </div>
        </div>
        
        <div class="sidebar-nav">
            <div class="nav-section">
                <div class="nav-section-title">Menu Utama</div>
                <ul class="nav flex-column">
                    <li class="nav-item">
                        <a href="/" class="nav-link {{ request()->is('/') ? 'active' : '' }}">
                            <i class="bi bi-speedometer2"></i>
                            Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="/users" class="nav-link {{ request()->is('users*') ? 'active' : '' }}">
                            <i class="bi bi-person-gear"></i>
                            User
                        </a>
                    </li>
                </ul>
            </div>

            <div class="nav-section">
                <div class="nav-section-title">Produk</div>
                <ul class="nav flex-column">
                    <li class="nav-item">
                        <a href="/products" class="nav-link {{ request()->is('products') && !request()->is('products/restock*') ? 'active' : '' }}">
                            <i class="bi bi-bag"></i>
                            Daftar Produk
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="/products/restock" class="nav-link {{ request()->is('products/restock*') ? 'active' : '' }}">
                            <i class="bi bi-box-arrow-in-down"></i>
                            Restock
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="/sizes" class="nav-link {{ request()->is('sizes*') ? 'active' : '' }}">
                            <i class="bi bi-aspect-ratio"></i>
                            Ukuran
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="/categories" class="nav-link {{ request()->is('categories*') ? 'active' : '' }}">
                            <i class="bi bi-collection"></i>
                            Kategori
                        </a>
                    </li>
                </ul>
            </div>

            <div class="nav-section">
                <div class="nav-section-title">Operasi</div>
                <ul class="nav flex-column">
                    <li class="nav-item">
                        <a href="/shifts" class="nav-link {{ request()->is('shifts*') ? 'active' : '' }}">
                            <i class="bi bi-calendar-check"></i>
                            Shift
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('sales-data.index') }}" class="nav-link {{ request()->is('sales-data*') ? 'active' : '' }}">
                            <i class="bi bi-graph-up-arrow"></i>
                            Riwayat Penjualan
                        </a>
                    </li>
                </ul>
            </div>

            <div class="nav-section">
                <div class="nav-section-title">Pengaturan</div>
                <ul class="nav flex-column">
                    <li class="nav-item">
                        <a href="{{ route('timezone.index') }}" class="nav-link {{ request()->is('timezone*') ? 'active' : '' }}">
                            <i class="bi bi-clock"></i>
                            Timezone
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('location.index') }}" class="nav-link {{ request()->is('location*') ? 'active' : '' }}">
                            <i class="bi bi-geo-alt"></i>
                            Location
                        </a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="main-content">
        <!-- Header -->
        <header class="header">
            <div class="header-content">
                <div class="header-left">
                    <button class="sidebar-toggle" id="sidebarToggle">
                        <i class="bi bi-list"></i>
                    </button>
                    <div class="digital-clock-container">
                        <div class="digital-clock" id="digitalClock">--:--:--</div>
                        <div class="clock-timezone" id="clockTimezone">WIB (GMT+7)</div>
                        <button class="btn btn-sm btn-outline-light ms-2" id="timezoneConfigBtn" data-bs-toggle="modal" data-bs-target="#timezoneConfigModal" title="Konfigurasi Timezone">
                            <i class="bi bi-gear"></i>
                        </button>
                    </div>
                </div>
                
                <div class="header-right">

                    

                    
                    <div class="dropdown">
                        <div class="profile-card" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://ui-avatars.com/api/?name={{ Auth::user()->name }}&background=random" class="profile-avatar">
                            <div class="profile-info">
                                <div class="profile-name">{{ Auth::user()->name }}</div>
                                <div class="profile-email">{{ Auth::user()->email }}</div>
                            </div>
                            <i class="bi bi-chevron-down profile-chevron"></i>
                        </div>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#userProfileModal">
                                <i class="bi bi-person"></i>Lihat Profil
                            </a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li>
                                <form action="{{ route('logout') }}" method="POST" class="d-inline">
                                    @csrf
                                    <button type="submit" class="dropdown-item text-danger">
                                        <i class="bi bi-box-arrow-right"></i>Keluar
                                    </button>
                                </form>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </header>

        <!-- Page Content -->
        <div class="page-content">
            {{--
                Pesan flash ditaruh di layout, bukan di tiap halaman: sebelumnya
                tidak satu pun view index menampilkan session('error'), sehingga
                penolakan seperti "kategori masih dipakai produk" hilang tanpa jejak
                dan admin mengira tombolnya rusak.
            --}}
            @if(session('success'))
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    <i class="bi bi-check-circle me-2"></i>{{ session('success') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Tutup"></button>
                </div>
            @endif

            @if(session('error'))
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <i class="bi bi-exclamation-triangle me-2"></i>{{ session('error') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Tutup"></button>
                </div>
            @endif

            {{ $slot }}
        </div>
    </div>

    <!-- Notification Dropdown -->
    <div class="dropdown-menu dropdown-menu-end p-0" style="width: 350px; display: none;" id="notificationDropdown">
        <div class="p-3 border-bottom d-flex justify-content-between align-items-center">
            <h6 class="mb-0 fw-semibold">Notifikasi</h6>
            <button class="btn btn-link btn-sm text-decoration-none" onclick="markAllNotificationsAsRead()">
                Tandai semua dibaca
            </button>
        </div>
        <div class="notification-list" style="max-height: 400px; overflow-y: auto;">
            <!-- Notifications will be loaded here -->
        </div>
    </div>

    <!-- User Profile Modal -->
    <div class="modal fade" id="userProfileModal" tabindex="-1" aria-labelledby="userProfileModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="userProfileModalLabel">Profil User</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div class="text-center mb-4">
                        <img src="https://ui-avatars.com/api/?name={{ Auth::user()->name }}&background=random" class="rounded-circle mb-3" width="100" height="100">
                        <h4 class="mb-1">{{ Auth::user()->name }}</h4>
                        <p class="text-muted">{{ Auth::user()->email }}</p>
                    </div>
                    <div class="list-group list-group-flush">
                        <div class="list-group-item d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="mb-0">Peran</h6>
                                <small class="text-muted">Administrator</small>
                            </div>
                            <span class="badge bg-primary rounded-pill">Aktif</span>
                        </div>
                        <div class="list-group-item d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="mb-0">Login Terakhir</h6>
                                <small class="text-muted">{{ now()->format('d M Y, H:i') }}</small>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <form action="{{ route('logout') }}" method="POST" class="w-100">
                        @csrf
                        <button type="submit" class="btn btn-danger w-100">Keluar</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Timezone Configuration Modal -->
    <div class="modal fade" id="timezoneConfigModal" tabindex="-1" aria-labelledby="timezoneConfigModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="timezoneConfigModalLabel">
                        <i class="bi bi-gear me-2"></i>
                        Konfigurasi Timezone
                    </h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">Waktu Saat Ini</label>
                        <div class="form-control-plaintext">
                            <div class="fs-4 fw-bold" id="modalCurrentTime">--:--:--</div>
                            <div class="text-muted" id="modalCurrentDate">-- -- ----</div>
                        </div>
                    </div>
                    <form id="timezoneConfigForm" method="POST" action="/timezone/update-form">
                        @csrf
                        <div class="mb-3">
                            <label for="modalTimezone" class="form-label">Pilih Timezone</label>
                            <select class="form-select" id="modalTimezone" name="timezone" required>
                                <option value="">-- Pilih Timezone --</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="modalTimezoneName" class="form-label">Nama Timezone</label>
                            <input type="text" class="form-control" id="modalTimezoneName" name="timezone_name" readonly>
                        </div>
                        <div class="mb-3">
                            <label for="modalUtcOffset" class="form-label">UTC Offset</label>
                            <input type="number" class="form-control" id="modalUtcOffset" name="utc_offset" readonly>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="submit" form="timezoneConfigForm" class="btn btn-primary">
                        <i class="bi bi-check-lg me-2"></i>
                        Simpan Perubahan
                    </button>
                </div>
            </div>
        </div>
    </div>

    <meta name="csrf-token" content="{{ csrf_token() }}">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="{{ asset('js/notifications.js') }}?v={{ filemtime(public_path('js/notifications.js')) }}"></script>
    @stack('scripts')
    <script>
        // Sidebar Toggle
        document.getElementById('sidebarToggle').addEventListener('click', function() {
            document.querySelector('.sidebar').classList.toggle('active');
            document.querySelector('.main-content').classList.toggle('active');
        });

        /*
         * Jam digital.
         *
         * Dulu ini memanggil /api/timezone/current setiap detik — ~3.600 request
         * per jam per tab, dan tiap request menyentuh database untuk membaca
         * baris timezone aktif. Sekarang: ambil waktu server sekali, lalu
         * berdetak di klien. Resync tiap 5 menit untuk mengoreksi drift dan
         * menangkap perubahan timezone dari halaman pengaturan.
         */
        let timeUpdateInterval;
        let clockOffsetMs = 0;   // selisih waktu server dengan jam lokal
        let clockTimezone = null;

        function renderClock() {
            const now = new Date(Date.now() + clockOffsetMs);
            const pad = (n) => String(n).padStart(2, '0');
            const time = `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;

            document.getElementById('digitalClock').textContent = time;

            const modal = document.getElementById('timezoneConfigModal');
            if (modal && modal.classList.contains('show')) {
                document.getElementById('modalCurrentTime').textContent = time;
            }
        }

        function syncClock() {
            fetch('/api/timezone/current')
                .then(r => r.json())
                .then(data => {
                    if (!data.success) return;

                    // Waktu server diurai jadi offset terhadap jam browser, supaya
                    // detik-detik berikutnya bisa dihitung tanpa request lagi.
                    const [h, m, s] = data.data.formatted.time.split(':').map(Number);
                    const local = new Date();
                    const server = new Date(local);
                    server.setHours(h, m, s, 0);
                    clockOffsetMs = server - local;

                    clockTimezone = data.data.formatted.timezone_display;
                    document.getElementById('clockTimezone').textContent = clockTimezone;

                    const modal = document.getElementById('timezoneConfigModal');
                    if (modal && modal.classList.contains('show')) {
                        document.getElementById('modalCurrentDate').textContent = data.data.formatted.date;
                    }
                })
                .catch(() => { /* jam lokal tetap berjalan; offset 0 */ });
        }

        function updateClock() { syncClock(); }   // dipakai setelah timezone diubah

        syncClock();
        renderClock();
        timeUpdateInterval = setInterval(renderClock, 1000);
        setInterval(syncClock, 5 * 60 * 1000);



        // Notification Badge Click
        document.getElementById('notificationDropdown').addEventListener('click', function(e) {
            e.preventDefault();
            const dropdown = document.querySelector('#notificationDropdown');
            dropdown.style.display = dropdown.style.display === 'block' ? 'none' : 'block';
        });

        // Close dropdown when clicking outside
        document.addEventListener('click', function(e) {
            if (!e.target.closest('.notification-badge') && !e.target.closest('#notificationDropdown')) {
                document.querySelector('#notificationDropdown').style.display = 'none';
            }
        });

        // Timezone Configuration
        let timezoneOptions = [];
        
        // Load timezone options when modal opens
        document.getElementById('timezoneConfigModal').addEventListener('show.bs.modal', function() {
            loadTimezoneOptions();
        });
        
        // Load timezone options
        function loadTimezoneOptions() {
            fetch('/api/timezone/options')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        timezoneOptions = data.data;
                        populateTimezoneSelect();
                    }
                })
                .catch(error => {
                    console.error('Error loading timezone options:', error);
                });
        }
        
        // Populate timezone select
        function populateTimezoneSelect() {
            const select = document.getElementById('modalTimezone');
            select.innerHTML = '<option value="">-- Pilih Timezone --</option>';
            
            timezoneOptions.forEach(option => {
                const optionElement = document.createElement('option');
                optionElement.value = option.timezone;
                optionElement.textContent = option.description;
                optionElement.dataset.name = option.timezone_name;
                optionElement.dataset.offset = option.utc_offset;
                select.appendChild(optionElement);
            });
            
            // Set current timezone as selected
            fetch('/api/timezone/current')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        select.value = data.data.timezone;
                        updateTimezoneFormFields();
                    }
                });
        }
        
        // Update timezone form fields when selection changes
        document.getElementById('modalTimezone').addEventListener('change', function() {
            updateTimezoneFormFields();
        });
        
        function updateTimezoneFormFields() {
            const selectedOption = document.getElementById('modalTimezone').selectedOptions[0];
            if (selectedOption && selectedOption.value) {
                document.getElementById('modalTimezoneName').value = selectedOption.dataset.name;
                document.getElementById('modalUtcOffset').value = selectedOption.dataset.offset;
            }
        }
        
        // Update timezone from modal
        function updateTimezoneFromModal() {
            const form = document.getElementById('timezoneConfigForm');
            const formData = new FormData(form);
            
            const timezone = formData.get('timezone');
            const timezoneName = formData.get('timezone_name');
            const utcOffset = formData.get('utc_offset');
            
            if (!timezone) {
                alert('Silakan pilih timezone');
                return;
            }
            
            fetch('/timezone/update-web', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
                },
                body: JSON.stringify({
                    timezone: timezone,
                    timezone_name: timezoneName,
                    utc_offset: utcOffset
                })
            })
            .then(response => {
                console.log('Response status:', response.status);
                return response.json();
            })
            .then(data => {
                console.log('Response data:', data);
                if (data.success) {
                    // Close modal
                    const modal = bootstrap.Modal.getInstance(document.getElementById('timezoneConfigModal'));
                    modal.hide();
                    
                    // Show success message
                    showNotification('success', data.message);
                    
                    // Update clock display immediately
                    updateClock();
                } else {
                    console.error('Error response:', data);
                    alert(data.message || 'Terjadi kesalahan saat mengubah timezone');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Terjadi kesalahan saat mengubah timezone: ' + error.message);
            });
        }
        
        // Show notification
        function showNotification(type, message) {
            const alertClass = type === 'success' ? 'alert-success' : 'alert-danger';
            const alertHtml = `
                <div class="alert ${alertClass} alert-dismissible fade show position-fixed" style="top: 20px; right: 20px; z-index: 9999;" role="alert">
                    ${message}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            `;
            
            document.body.insertAdjacentHTML('beforeend', alertHtml);
            
            // Auto remove alert after 3 seconds
            setTimeout(() => {
                const alert = document.querySelector('.alert');
                if (alert) {
                    alert.remove();
                }
            }, 3000);
        }
        
        // Clean up interval when page unloads
        window.addEventListener('beforeunload', function() {
            if (timeUpdateInterval) {
                clearInterval(timeUpdateInterval);
            }
        });

    </script>
</body>
</html>