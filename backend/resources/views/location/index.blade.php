<x-admin-layout title="Lokasi">
    @push('styles')
    <!-- Leaflet CSS -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
          integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="
          crossorigin=""/>

    <!-- Leaflet JavaScript with fallback -->
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
            integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="
            crossorigin=""></script>
    <script>
        // Fallback if primary CDN fails
        if (typeof L === 'undefined') {
            console.warn('Primary Leaflet CDN failed, trying fallback...');
            const script = document.createElement('script');
            script.src = 'https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.js';
            script.crossOrigin = 'anonymous';
            script.onload = function () { console.log('Fallback Leaflet CDN loaded successfully'); };
            script.onerror = function () { console.error('All Leaflet CDNs failed'); };
            document.head.appendChild(script);
        }
    </script>
    <style>
        /*
         * Yang khas halaman ini cuma editor petanya: peta Leaflet dengan overlay
         * pencarian, tombol kontrol, dan panel cadangan bila peta gagal dimuat.
         * Header, kartu, tabel, badge, dan modal memakai admin.css + Bootstrap.
         */
        .loc-map-wrap {
            position: relative;
            height: 62vh;
            min-height: 380px;
            background: var(--neutral-100);
        }

        #map {
            position: absolute;
            inset: 0;
        }

        /* z-index 1000: pane Leaflet berhenti di 700, kontrolnya di 800. */
        .loc-map-search {
            position: absolute;
            top: 12px;
            left: 50%;
            transform: translateX(-50%);
            width: min(420px, calc(100% - 7rem));
            z-index: 1000;
        }

        .loc-suggestions {
            display: none;
            margin-top: 4px;
            max-height: 220px;
            overflow-y: auto;
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-sm);
            box-shadow: var(--shadow-lg);
        }

        .loc-suggestion {
            padding: 0.625rem 0.875rem;
            border-bottom: 1px solid var(--border-color);
            font-size: 0.8125rem;
            cursor: pointer;
        }

        .loc-suggestion:last-child { border-bottom: 0; }
        .loc-suggestion:hover { background: var(--light-bg); }
        .loc-suggestion strong { display: block; color: var(--text-primary); }
        .loc-suggestion span { color: var(--text-secondary); }

        .loc-map-tools {
            position: absolute;
            top: 12px;
            right: 12px;
            z-index: 1000;
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }

        .loc-map-tools .btn.active {
            background: var(--violet-600);
            color: var(--neutral-0);
        }

        .loc-map-fallback {
            position: absolute;
            inset: 0;
            z-index: 1100;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 0.75rem;
            padding: 2rem;
            text-align: center;
            background: var(--light-bg);
            color: var(--text-secondary);
        }

        .loc-map-fallback i { font-size: 2.5rem; opacity: 0.5; }

        @media (max-width: 991.98px) {
            .loc-map-wrap { height: 45vh; min-height: 300px; }
        }
    </style>
    @endpush

    <div class="page-header">
        <h1 class="page-title">Manajemen Lokasi</h1>
        <p class="page-subtitle">Titik pusat geofence absensi. Hanya satu lokasi yang aktif — itulah yang dipakai untuk memvalidasi check-in karyawan.</p>
    </div>

    <div class="page-actions">
        <button type="button" class="btn btn-primary" onclick="openLocationModal()">
            <i class="bi bi-plus-lg"></i>
            Tambah Lokasi
        </button>
    </div>

    <!-- Lokasi aktif -->
    <div class="card p-4 mb-4">
        <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
            <div>
                <div class="d-flex align-items-center gap-2 mb-1">
                    <span class="text-secondary small text-uppercase">Lokasi aktif</span>
                    <span class="status-badge active">Aktif</span>
                </div>
                <h2 class="h4 fw-semibold mb-1">{{ $activeLocation->name }}</h2>
                <p class="text-secondary mb-0">{{ $activeLocation->getFormattedAddress() ?: 'Alamat belum diisi' }}</p>
            </div>
            <a href="{{ $activeLocation->getGoogleMapsUrl() }}" target="_blank" rel="noopener" class="btn btn-secondary">
                <i class="bi bi-map"></i>
                Lihat di Google Maps
            </a>
        </div>

        <div class="row g-3 mt-1">
            <div class="col-sm-4">
                <div class="text-secondary small">Koordinat</div>
                <div class="font-monospace">{{ $activeLocation->latitude }}, {{ $activeLocation->longitude }}</div>
            </div>
            <div class="col-sm-4">
                <div class="text-secondary small">Koordinat (DMS)</div>
                <div class="font-monospace">{{ $activeLocation->getCoordinatesInDMS()['latitude_dms'] }}, {{ $activeLocation->getCoordinatesInDMS()['longitude_dms'] }}</div>
            </div>
            <div class="col-sm-4">
                <div class="text-secondary small">Radius geofence</div>
                <div>{{ $activeLocation->radius_meters }} meter</div>
            </div>
        </div>
    </div>

    <h5 class="section-title mb-3">Semua Lokasi</h5>

    <!-- Daftar lokasi -->
    <div class="modern-table">
        <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr>
                        <th>Lokasi</th>
                        <th>Koordinat</th>
                        <th>Radius</th>
                        <th>Alamat</th>
                        <th>Status</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($locationSettings as $location)
                        <tr data-location-id="{{ $location->id }}"
                            data-location-name="{{ $location->name }}"
                            data-location-description="{{ $location->description ?? '' }}"
                            data-location-latitude="{{ $location->latitude }}"
                            data-location-longitude="{{ $location->longitude }}"
                            data-location-radius="{{ $location->radius_meters }}"
                            data-location-address="{{ $location->address ?? '' }}"
                            data-location-city="{{ $location->city ?? '' }}"
                            data-location-province="{{ $location->province ?? '' }}"
                            data-location-active="{{ $location->is_active ? '1' : '0' }}">
                            <td>
                                <div class="category-name">{{ $location->name }}</div>
                                @if($location->description)
                                    <div class="category-description">{{ $location->description }}</div>
                                @endif
                            </td>
                            <td><span class="font-monospace small">{{ $location->latitude }}, {{ $location->longitude }}</span></td>
                            <td><span class="code-badge">{{ $location->radius_meters }} m</span></td>
                            <td>
                                @if($location->getFormattedAddress())
                                    <span class="category-description">{{ Str::limit($location->getFormattedAddress(), 50) }}</span>
                                @else
                                    <span class="text-secondary fst-italic">Tidak ada alamat</span>
                                @endif
                            </td>
                            <td>
                                <span class="status-badge {{ $location->is_active ? 'active' : 'inactive' }}">
                                    {{ $location->is_active ? 'Aktif' : 'Tidak Aktif' }}
                                </span>
                            </td>
                            <td>
                                <div class="d-flex align-items-center gap-1">
                                    @unless($location->is_active)
                                        <form method="POST" action="{{ route('location.activate', $location) }}" class="d-inline">
                                            @csrf
                                            <button type="submit" class="action-btn text-success" title="Jadikan lokasi aktif">
                                                <i class="bi bi-check-circle"></i>
                                            </button>
                                        </form>
                                    @endunless
                                    <button type="button" class="action-btn edit" title="Ubah" onclick="editLocation({{ $location->id }})">
                                        <i class="bi bi-pencil"></i>
                                    </button>
                                    <a href="{{ $location->getGoogleMapsUrl() }}" target="_blank" rel="noopener" class="action-btn view text-decoration-none" title="Lihat di Google Maps">
                                        <i class="bi bi-map"></i>
                                    </a>
                                    @unless($location->is_active)
                                        <form method="POST" action="{{ route('location.destroy', $location) }}" class="d-inline"
                                              onsubmit="return confirm('Hapus lokasi ini?')">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="action-btn delete" title="Hapus">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </form>
                                    @endunless
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6">
                                <div class="empty-state">
                                    <i class="bi bi-geo-alt empty-state-icon"></i>
                                    <div class="empty-state-title">Belum ada lokasi</div>
                                    <div class="empty-state-description">Tambahkan lokasi pertama untuk menentukan area absensi</div>
                                    <button type="button" class="btn btn-primary" onclick="openLocationModal()">
                                        <i class="bi bi-plus-lg"></i>
                                        Tambah Lokasi
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- Editor lokasi: formulir di kiri, peta di kanan -->
    <div class="modal fade" id="locationModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-xl modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="modalTitle">Tambah Lokasi Baru</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Tutup"></button>
                </div>

                <div class="modal-body p-0">
                    <div class="row g-0">
                        <div class="col-lg-5 p-4 border-end">
                            <form id="locationForm" method="POST">
                                @csrf
                                <div id="formMethod"></div>

                                <div class="form-group">
                                    <label class="form-label" for="name">Nama Lokasi *</label>
                                    <input type="text" class="form-control" id="name" name="name" required>
                                </div>

                                <div class="form-group">
                                    <label class="form-label" for="description">Deskripsi</label>
                                    <textarea class="form-control" id="description" name="description" rows="2"></textarea>
                                </div>

                                <div class="row g-2">
                                    <div class="col-6 form-group">
                                        <label class="form-label" for="latitude">Latitude *</label>
                                        <input type="number" step="any" class="form-control" id="latitude" name="latitude" required>
                                    </div>
                                    <div class="col-6 form-group">
                                        <label class="form-label" for="longitude">Longitude *</label>
                                        <input type="number" step="any" class="form-control" id="longitude" name="longitude" required>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label class="form-label" for="radius_meters">Radius Geofence (meter) *</label>
                                    <input type="number" class="form-control" id="radius_meters" name="radius_meters"
                                           value="100" min="1" max="10000" required>
                                    <div class="form-text">Check-in hanya diterima di dalam radius ini dari titik lokasi.</div>
                                </div>

                                <div class="form-group mb-0">
                                    <label class="form-label">Alamat Terdeteksi</label>
                                    <p class="text-secondary small mb-0" id="displayAddress">Klik peta untuk mengatur titik.</p>
                                </div>

                                <input type="hidden" id="address" name="address">
                                <input type="hidden" id="city" name="city">
                                <input type="hidden" id="province" name="province">
                                <input type="hidden" id="is_active" name="is_active" value="0">
                            </form>
                        </div>

                        <div class="col-lg-7">
                            <div class="loc-map-wrap">
                                <div id="map"></div>

                                <div class="loc-map-search">
                                    <input type="text" id="searchBox" class="form-control"
                                           placeholder="Cari lokasi... (contoh: Jakarta, Semarang, Mall)"
                                           autocomplete="off">
                                    <div class="loc-suggestions" id="searchSuggestions"></div>
                                </div>

                                <div class="loc-map-tools">
                                    <button type="button" class="btn btn-light border" id="currentLocationBtn" title="Pakai lokasi saya">
                                        <i class="bi bi-crosshair"></i>
                                    </button>
                                    <button type="button" class="btn btn-light border" id="centerMapBtn" title="Pusatkan ke titik">
                                        <i class="bi bi-geo-alt"></i>
                                    </button>
                                    <button type="button" class="btn btn-light border" id="toggleSatelliteBtn" title="Peta satelit">
                                        <i class="bi bi-globe-americas"></i>
                                    </button>
                                </div>

                                <div class="loc-map-fallback d-none" id="mapFallback">
                                    <i class="bi bi-map"></i>
                                    <p class="mb-0">Peta tidak dapat dimuat. Koordinat masih bisa diisi manual pada formulir.</p>
                                    <button type="button" class="btn btn-primary" id="retryMapBtn">Coba Lagi</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                    <button type="submit" class="btn btn-primary" form="locationForm" id="submitBtn">Tambah Lokasi</button>
                </div>
            </div>
        </div>
    </div>

    @push('scripts')
    <script>
        const LOC_DEFAULT_CENTER = [-6.753417, 110.843639];   // Semarang
        const LOC_OSM_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
        const LOC_SAT_URL = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
        const LOC_BLANK_TILE = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

        let map = null;
        let marker = null;
        let geofence = null;
        let isSatellite = false;
        let pendingLocation = null;

        const modalEl = document.getElementById('locationModal');
        const locationModal = new bootstrap.Modal(modalEl);

        const el = (id) => document.getElementById(id);

        /* ---------- modal ---------- */

        function openLocationModal(data = null) {
            const form = el('locationForm');
            form.reset();
            el('formMethod').innerHTML = '';
            el('displayAddress').textContent = 'Klik peta untuk mengatur titik.';
            pendingLocation = data;

            if (data) {
                el('modalTitle').textContent = 'Ubah Lokasi';
                el('submitBtn').textContent = 'Simpan Perubahan';
                form.action = '/location/' + data.id;
                el('formMethod').innerHTML = '<input type="hidden" name="_method" value="PUT">';
                el('name').value = data.name || '';
                el('description').value = data.description || '';
                el('latitude').value = data.latitude || '';
                el('longitude').value = data.longitude || '';
                el('radius_meters').value = data.radius_meters || 100;
                el('address').value = data.address || '';
                el('city').value = data.city || '';
                el('province').value = data.province || '';
                el('is_active').value = data.is_active ? '1' : '0';
                if (data.address) el('displayAddress').textContent = data.address;
            } else {
                el('modalTitle').textContent = 'Tambah Lokasi Baru';
                el('submitBtn').textContent = 'Tambah Lokasi';
                form.action = '{{ route("location.store") }}';
                el('is_active').value = '0';
            }

            locationModal.show();
        }

        function editLocation(locationId) {
            const row = document.querySelector(`[data-location-id="${locationId}"]`);
            if (!row) {
                alert('Lokasi tidak ditemukan.');
                return;
            }
            openLocationModal({
                id: locationId,
                name: row.dataset.locationName,
                description: row.dataset.locationDescription,
                latitude: parseFloat(row.dataset.locationLatitude),
                longitude: parseFloat(row.dataset.locationLongitude),
                radius_meters: parseInt(row.dataset.locationRadius, 10),
                address: row.dataset.locationAddress,
                city: row.dataset.locationCity,
                province: row.dataset.locationProvince,
                is_active: row.dataset.locationActive === '1'
            });
        }

        // Peta dibuat setelah modal tampil supaya Leaflet mengukur kontainer yang
        // sudah punya tinggi; dibongkar lagi saat ditutup agar tidak menumpuk.
        modalEl.addEventListener('shown.bs.modal', () => startMap(pendingLocation));

        modalEl.addEventListener('hidden.bs.modal', function () {
            if (map) { map.remove(); map = null; }
            marker = null;
            geofence = null;
            pendingLocation = null;
            hideSuggestions();
        });

        /* ---------- peta ---------- */

        // Leaflet dimuat dari CDN; kalau yang utama gagal, fallback jsDelivr masih
        // dalam perjalanan. Tunggu sampai L terdefinisi sebelum menyerah.
        function startMap(data, attempt = 0) {
            if (typeof L === 'undefined' || !L.map) {
                if (attempt < 15) {
                    setTimeout(() => startMap(data, attempt + 1), 300);
                    return;
                }
                console.error('Leaflet gagal dimuat setelah percobaan maksimum');
                showMapFallback();
                return;
            }

            if (!navigator.onLine) {
                showMapFallback();
                return;
            }

            try {
                initMap(data);
            } catch (error) {
                console.error('Gagal menyiapkan peta:', error);
                showMapFallback();
            }
        }

        function initMap(data) {
            if (map) { map.remove(); map = null; }
            el('mapFallback').classList.add('d-none');

            const center = data && !isNaN(parseFloat(data.latitude))
                ? [parseFloat(data.latitude), parseFloat(data.longitude)]
                : LOC_DEFAULT_CENTER;

            map = L.map('map').setView(center, 16);
            map.osmLayer = L.tileLayer(LOC_OSM_URL, {
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                maxZoom: 19,
                errorTileUrl: LOC_BLANK_TILE
            }).addTo(map);
            map.satelliteLayer = L.tileLayer(LOC_SAT_URL, {
                attribution: '© Esri',
                maxZoom: 19,
                errorTileUrl: LOC_BLANK_TILE
            });

            isSatellite = false;
            el('toggleSatelliteBtn').classList.remove('active');

            map.on('click', function (e) {
                setMarker(e.latlng.lat, e.latlng.lng);
                reverseGeocode(e.latlng.lat, e.latlng.lng);
            });

            setMarker(center[0], center[1]);
            if (!data) reverseGeocode(center[0], center[1]);
        }

        function setMarker(lat, lng) {
            if (marker) map.removeLayer(marker);

            marker = L.marker([lat, lng], { draggable: true }).addTo(map);
            marker.on('dragend', function (e) {
                const pos = e.target.getLatLng();
                setCoordinates(pos.lat, pos.lng);
                drawGeofence();
                reverseGeocode(pos.lat, pos.lng);
            });

            setCoordinates(lat, lng);
            drawGeofence();
        }

        function setCoordinates(lat, lng) {
            el('latitude').value = Number(lat).toFixed(8);
            el('longitude').value = Number(lng).toFixed(8);
        }

        // Lingkaran radius = geofence yang dipakai Haversine di backend, jadi
        // admin melihat persis area yang diterima saat check-in.
        function drawGeofence() {
            if (!map) return;

            const lat = parseFloat(el('latitude').value);
            const lng = parseFloat(el('longitude').value);
            const radius = parseInt(el('radius_meters').value, 10);
            if (isNaN(lat) || isNaN(lng) || isNaN(radius)) return;

            if (geofence) {
                geofence.setLatLng([lat, lng]).setRadius(radius);
            } else {
                geofence = L.circle([lat, lng], {
                    radius: radius,
                    color: '#7c3aed',
                    weight: 2,
                    fillColor: '#7c3aed',
                    fillOpacity: 0.12
                }).addTo(map);
            }
        }

        function showMapFallback() {
            el('mapFallback').classList.remove('d-none');
        }

        /* ---------- geocoding (Nominatim) ---------- */

        function reverseGeocode(lat, lng) {
            fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&addressdetails=1`)
                .then(response => response.json())
                .then(data => {
                    if (!data || !data.display_name) {
                        el('displayAddress').textContent = 'Alamat tidak ditemukan';
                        return;
                    }
                    const address = data.address || {};
                    el('address').value = [address.house_number, address.road].filter(Boolean).join(' ');
                    el('city').value = address.city || address.town || address.village || '';
                    el('province').value = address.state || address.province || '';
                    el('displayAddress').textContent = data.display_name;
                })
                .catch(() => { el('displayAddress').textContent = 'Alamat tidak ditemukan'; });
        }

        function showSuggestions(results) {
            const box = el('searchSuggestions');
            box.innerHTML = '';

            results.forEach(result => {
                const item = document.createElement('div');
                item.className = 'loc-suggestion';
                item.innerHTML = '<strong></strong><span></span>';
                item.querySelector('strong').textContent = result.display_name.split(',')[0];
                item.querySelector('span').textContent = result.display_name;
                item.addEventListener('click', () => {
                    el('searchBox').value = result.display_name;
                    hideSuggestions();
                    goToPoint(parseFloat(result.lat), parseFloat(result.lon));
                });
                box.appendChild(item);
            });

            box.style.display = results.length ? 'block' : 'none';
        }

        function hideSuggestions() {
            el('searchSuggestions').style.display = 'none';
        }

        function goToPoint(lat, lng) {
            if (!map) return;
            setMarker(lat, lng);
            map.setView([lat, lng], 16);
            reverseGeocode(lat, lng);
        }

        function searchLocation(query) {
            const searchBox = el('searchBox');
            searchBox.disabled = true;

            fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1&addressdetails=1`)
                .then(response => response.json())
                .then(data => {
                    searchBox.disabled = false;
                    if (data && data.length > 0) {
                        searchBox.value = data[0].display_name;
                        goToPoint(parseFloat(data[0].lat), parseFloat(data[0].lon));
                    } else {
                        alert('Lokasi tidak ditemukan. Coba kata kunci lain.');
                    }
                })
                .catch(() => {
                    searchBox.disabled = false;
                    alert('Pencarian gagal. Periksa koneksi internet Anda.');
                });
        }

        /* ---------- kontrol (dipasang sekali, bukan tiap peta dibuat) ---------- */

        let searchTimer;

        el('searchBox').addEventListener('input', function () {
            clearTimeout(searchTimer);
            const query = this.value.trim();
            if (query.length <= 2) { hideSuggestions(); return; }

            searchTimer = setTimeout(() => {
                fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=5&addressdetails=1`)
                    .then(response => response.json())
                    .then(data => showSuggestions(data || []))
                    .catch(() => hideSuggestions());
            }, 300);
        });

        el('searchBox').addEventListener('keydown', function (e) {
            if (e.key !== 'Enter') return;
            e.preventDefault();
            const query = this.value.trim();
            if (!query) return;
            hideSuggestions();
            searchLocation(query);
        });

        document.addEventListener('click', function (e) {
            if (!e.target.closest('.loc-map-search')) hideSuggestions();
        });

        el('currentLocationBtn').addEventListener('click', function () {
            if (!map) return;
            if (!navigator.geolocation) {
                alert('Browser ini tidak mendukung deteksi lokasi.');
                return;
            }
            navigator.geolocation.getCurrentPosition(
                pos => goToPoint(pos.coords.latitude, pos.coords.longitude),
                error => alert('Gagal mengambil lokasi saat ini: ' + error.message)
            );
        });

        el('centerMapBtn').addEventListener('click', function () {
            if (!map || !marker) return;
            const pos = marker.getLatLng();
            map.setView([pos.lat, pos.lng], 16);
        });

        el('toggleSatelliteBtn').addEventListener('click', function () {
            if (!map) return;
            isSatellite = !isSatellite;
            if (isSatellite) {
                map.removeLayer(map.osmLayer);
                map.satelliteLayer.addTo(map);
            } else {
                map.removeLayer(map.satelliteLayer);
                map.osmLayer.addTo(map);
            }
            this.classList.toggle('active', isSatellite);
        });

        el('retryMapBtn').addEventListener('click', function () {
            el('mapFallback').classList.add('d-none');
            startMap(pendingLocation);
        });

        // Koordinat boleh diketik manual — peta mengikuti, bukan sebaliknya.
        ['latitude', 'longitude'].forEach(id => el(id).addEventListener('change', function () {
            const lat = parseFloat(el('latitude').value);
            const lng = parseFloat(el('longitude').value);
            if (isNaN(lat) || isNaN(lng) || !map) return;
            setMarker(lat, lng);
            map.setView([lat, lng], map.getZoom());
        }));

        el('radius_meters').addEventListener('input', drawGeofence);
    </script>
    @endpush
</x-admin-layout>
