<x-admin-layout>
    <x-slot name="title">History Penjualan</x-slot>

    @php
        /*
         * items.product sudah di-eager-load controller; ukuran (variant.size) belum.
         * loadMissing menariknya dalam dua query untuk seluruh halaman, bukan per baris.
         */
        $sales->getCollection()->loadMissing('items.variant.size');

        $paymentIcons = ['cash' => 'bi-cash', 'qris' => 'bi-qr-code', 'transfer' => 'bi-bank'];
        $statusClasses = ['completed' => 'completed', 'pending' => 'pending', 'cancelled' => 'inactive'];
        $statusIcons = ['completed' => 'bi-check-circle', 'pending' => 'bi-hourglass-split', 'cancelled' => 'bi-x-circle'];
    @endphp

    <div class="page-header d-flex justify-content-between align-items-start gap-3 flex-wrap">
        <div>
            <h1 class="page-title">History Penjualan</h1>
            <p class="page-subtitle">Riwayat transaksi kasir.</p>
        </div>
        <button type="button" class="btn btn-outline-primary" onclick="exportToExcel()">
            <i class="bi bi-file-earmark-excel"></i> Export Excel
        </button>
    </div>

    <div class="search-filter-container">
        <div class="search-box">
            <i class="bi bi-search search-icon"></i>
            <input type="text" placeholder="Cari ID transaksi, kasir, produk, status..." id="searchInput" aria-label="Cari transaksi">
        </div>
        <div class="filter-dropdown">
            <button class="filter-btn" id="filterBtn" type="button">
                <i class="bi bi-funnel"></i> <span id="filterLabel">Semua Metode</span> <i class="bi bi-chevron-down"></i>
            </button>
            <div class="filter-menu" id="filterMenu">
                <div class="filter-item active" data-filter="all">Semua Metode</div>
                <div class="filter-item" data-filter="cash">Tunai</div>
                <div class="filter-item" data-filter="qris">QRIS</div>
                <div class="filter-item" data-filter="transfer">Transfer Bank</div>
            </div>
        </div>
    </div>

    @if($sales->isEmpty())
        <div class="card empty-state">
            <i class="bi bi-inbox empty-state-icon"></i>
            <div class="empty-state-title">Tidak ada data penjualan</div>
            <div class="empty-state-description">Belum ada transaksi penjualan yang tercatat.</div>
        </div>
    @else
        <div class="modern-table">
            <div class="table-responsive">
                <table class="table align-middle" id="salesTable">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Tanggal</th>
                            <th>Kasir</th>
                            <th>Metode</th>
                            <th>Status</th>
                            <th>Item</th>
                            <th class="text-end">Total</th>
                            <th class="text-end">Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($sales as $sale)
                            @php
                                $method = $sale->payment_method ?? '';
                                $status = $sale->status ?? '';
                            @endphp
                            <tr class="sale-row" data-payment="{{ strtolower($method) }}">
                                <td><span class="code-badge trx-id">#{{ str_pad($sale->id, 5, '0', STR_PAD_LEFT) }}</span></td>
                                <td>
                                    <div class="user-name">{{ $sale->created_at->format('d M Y') }}</div>
                                    <div class="text-secondary small">{{ $sale->created_at->format('H:i') }}</div>
                                </td>
                                <td>
                                    <div class="d-flex align-items-center gap-2">
                                        <img src="https://ui-avatars.com/api/?name={{ urlencode($sale->user->name ?? 'Unknown') }}&background=random"
                                             alt="" width="32" height="32" class="rounded-circle flex-shrink-0">
                                        <span class="user-name">{{ $sale->user->name ?? 'Tidak diketahui' }}</span>
                                    </div>
                                </td>
                                <td>
                                    <span class="code-badge">
                                        <i class="bi {{ $paymentIcons[$method] ?? 'bi-credit-card' }}"></i>
                                        {{ $sale->formatted_payment_method }}
                                    </span>
                                </td>
                                <td>
                                    {{-- Status selalu ikon + teks. --}}
                                    <span class="status-badge {{ $statusClasses[$status] ?? 'pending' }}">
                                        <i class="bi {{ $statusIcons[$status] ?? 'bi-question-circle' }}"></i>
                                        {{ $sale->formatted_status }}
                                    </span>
                                </td>
                                <td>
                                    <div class="small">
                                        @foreach($sale->items->take(3) as $item)
                                            <div>
                                                {{ $item->quantity }}&times; {{ $item->product->name ?? 'Produk dihapus' }}
                                                {{-- product_variant_id NULL pada transaksi POS lama. --}}
                                                @if($item->variant?->size?->code)
                                                    <span class="code-badge">{{ $item->variant->size->code }}</span>
                                                @endif
                                            </div>
                                        @endforeach
                                        @if($sale->items->count() > 3)
                                            <div class="text-secondary">+{{ $sale->items->count() - 3 }} item lainnya</div>
                                        @endif
                                        @if($sale->items->isEmpty())
                                            <span class="text-secondary">—</span>
                                        @endif
                                    </div>
                                </td>
                                <td class="text-end"><span class="price-info price-amount">Rp {{ number_format($sale->total_amount, 0, ',', '.') }}</span></td>
                                <td class="text-end">
                                    <button type="button" class="btn btn-sm btn-outline-primary" onclick="viewTransaction({{ $sale->id }})">
                                        <i class="bi bi-eye"></i> Detail
                                    </button>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        <div class="pagination-container">
            <div class="pagination-info">
                Menampilkan {{ $sales->firstItem() }}–{{ $sales->lastItem() }} dari {{ $sales->total() }} transaksi
                <span id="filterInfo" hidden></span>
            </div>
            @if($sales->hasPages())
                {{ $sales->links('vendor.pagination.bootstrap-5') }}
            @endif
        </div>
    @endif

    <div class="modal fade" id="transactionModal" tabindex="-1" aria-labelledby="transactionModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="transactionModalLabel">Detail Transaksi</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Tutup"></button>
                </div>
                <div class="modal-body" id="transactionModalContent"></div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Tutup</button>
                </div>
            </div>
        </div>
    </div>

    <style>
        /*
         * Halaman ini memakai .page-header, .search-filter-container, .search-box,
         * .filter-*, .modern-table, .code-badge, .status-badge, .price-amount,
         * .empty-state*, .pagination-container, dan .loading-spinner dari admin.css.
         * Sisanya hanya satu hal yang benar-benar lokal: nomor transaksi monospace.
         */
        .trx-id {
            font-family: 'JetBrains Mono', monospace;
            color: var(--text-primary);
            letter-spacing: -0.02em;
        }
    </style>

    <script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
    <script>
        const saleRows = document.querySelectorAll('#salesTable tbody tr');
        const filterInfo = document.getElementById('filterInfo');
        let currentSearch = '';
        let currentFilter = 'all';

        function applyFilters() {
            let visible = 0;
            saleRows.forEach(row => {
                const matchesSearch = !currentSearch || row.textContent.toLowerCase().includes(currentSearch);
                const matchesFilter = currentFilter === 'all' || row.dataset.payment === currentFilter;
                const show = matchesSearch && matchesFilter;
                row.hidden = !show;
                if (show) visible++;
            });
            if (filterInfo) {
                filterInfo.hidden = visible === saleRows.length;
                filterInfo.textContent = ' — ' + visible + ' baris cocok dengan filter di halaman ini';
            }
        }

        document.getElementById('searchInput').addEventListener('input', function () {
            currentSearch = this.value.trim().toLowerCase();
            applyFilters();
        });

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
                document.getElementById('filterLabel').textContent = this.textContent.trim();
                applyFilters();
                filterMenu.classList.remove('show');
            });
        });

        function escapeHtml(value) {
            return String(value ?? '').replace(/[&<>"']/g, c => ({
                '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
            })[c]);
        }

        const rupiah = value => 'Rp ' + Number(value || 0).toLocaleString('id-ID');

        function viewTransaction(saleId) {
            const modal = new bootstrap.Modal(document.getElementById('transactionModal'));
            const content = document.getElementById('transactionModalContent');

            content.innerHTML = `
                <div class="text-center py-4">
                    <div class="loading-spinner mx-auto"></div>
                    <p class="text-secondary mt-3 mb-0">Memuat detail transaksi...</p>
                </div>`;
            modal.show();

            fetch(`/sales-data/${saleId}/details`)
                .then(response => {
                    if (!response.ok) throw new Error('Transaksi tidak ditemukan');
                    return response.json();
                })
                .then(data => {
                    const rows = data.items.map(item => `
                        <tr>
                            <td>${escapeHtml(item.nama_produk)}<div class="text-secondary small">${escapeHtml(item.kode_produk)}</div></td>
                            <td class="text-end">${rupiah(item.harga_satuan)}</td>
                            <td class="text-end">${escapeHtml(item.jumlah)}</td>
                            <td class="text-end">${rupiah(item.subtotal)}</td>
                        </tr>`).join('');

                    content.innerHTML = `
                        <div class="row g-3 mb-4">
                            <div class="col-md-7">
                                <dl class="row mb-0 small">
                                    <dt class="col-5 fw-normal text-secondary">ID Transaksi</dt>
                                    <dd class="col-7 mb-1">#${String(data.id).padStart(5, '0')}</dd>
                                    <dt class="col-5 fw-normal text-secondary">Tanggal</dt>
                                    <dd class="col-7 mb-1">${escapeHtml(data.tanggal)}</dd>
                                    <dt class="col-5 fw-normal text-secondary">Kasir</dt>
                                    <dd class="col-7 mb-1">${escapeHtml(data.karyawan)}</dd>
                                    <dt class="col-5 fw-normal text-secondary">Metode Pembayaran</dt>
                                    <dd class="col-7 mb-1">${escapeHtml(data.metode_pembayaran)}</dd>
                                    <dt class="col-5 fw-normal text-secondary">Status</dt>
                                    <dd class="col-7 mb-0">${escapeHtml(data.status)}</dd>
                                </dl>
                            </div>
                            <div class="col-md-5">
                                <div class="card h-100 d-flex justify-content-center text-center p-3">
                                    <div class="dash-kpi-label">Total Transaksi</div>
                                    <div class="dash-kpi-value">${rupiah(data.total_harga)}</div>
                                    <div class="dash-kpi-label">${data.items.length} item produk</div>
                                </div>
                            </div>
                        </div>
                        <h6>Rincian Produk</h6>
                        <div class="table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead>
                                    <tr>
                                        <th>Produk</th>
                                        <th class="text-end">Harga</th>
                                        <th class="text-end">Jumlah</th>
                                        <th class="text-end">Subtotal</th>
                                    </tr>
                                </thead>
                                <tbody>${rows}</tbody>
                            </table>
                        </div>`;
                })
                .catch(error => {
                    content.innerHTML = `
                        <div class="empty-state">
                            <i class="bi bi-exclamation-triangle empty-state-icon"></i>
                            <div class="empty-state-title">Gagal memuat detail</div>
                            <div class="empty-state-description">${escapeHtml(error.message)}</div>
                        </div>`;
                });
        }

        function exportToExcel() {
            const table = document.getElementById('salesTable');
            if (!table) return;
            const wb = XLSX.utils.table_to_book(table, { sheet: 'Penjualan' });
            XLSX.writeFile(wb, `penjualan_${new Date().toISOString().split('T')[0]}.xlsx`);
        }
    </script>
</x-admin-layout>
