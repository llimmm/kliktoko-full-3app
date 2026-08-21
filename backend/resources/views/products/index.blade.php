<x-admin-layout title="Produk">
    <div class="page-header">
        <h1 class="page-title">Manajemen Produk</h1>
        <p class="page-subtitle">Kelola produk dan stok per ukuran</p>
    </div>

    <div class="page-actions">
        @php
            // Dihitung dari product_variants, bukan dari halaman yang sedang tampil:
            // stok per ukuran adalah sumber kebenaran, dan hitungan lama hanya
            // menjumlah 10 produk pada halaman aktif sehingga selalu terlalu kecil.
            $restockCount = \App\Models\ProductVariant::where('stock_quantity', '<=', 5)->count();
        @endphp
        @if($restockCount > 0)
            <a href="{{ route('products.restock') }}" class="btn btn-outline-warning">
                <i class="bi bi-arrow-clockwise"></i>
                Restock ({{ $restockCount }})
            </a>
        @endif
        <a href="{{ route('products.create') }}" class="btn btn-primary">
            <i class="bi bi-plus-lg"></i>
            Tambah Produk Baru
        </a>
    </div>

    {{-- Pencarian diproses server: hasilnya ikut paginasi, bukan hanya menyaring
         10 baris yang kebetulan sedang tampil. --}}
    <form method="GET" action="{{ route('products.index') }}" class="search-filter-container">
        <div class="search-box">
            <i class="bi bi-search search-icon"></i>
            <input type="search" name="search" value="{{ request('search') }}"
                   placeholder="Cari produk berdasarkan nama atau kode...">
        </div>
        <button type="submit" class="btn btn-primary">Cari</button>
        @if(request('search'))
            <a href="{{ route('products.index') }}" class="btn btn-secondary">Reset</a>
        @endif
    </form>

    <div class="modern-table products-table">
        <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr>
                        <th>Produk</th>
                        <th>Kode</th>
                        <th>Kategori</th>
                        <th>Stok per Ukuran</th>
                        <th>Total</th>
                        <th>Harga</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($products as $product)
                        <tr>
                            <td>
                                <div class="d-flex align-items-center gap-3">
                                    <div class="product-image">
                                        @if($product->image_path)
                                            <img src="{{ Storage::url($product->image_path) }}" alt="{{ $product->name }}">
                                        @else
                                            <div class="placeholder-image"><i class="bi bi-image"></i></div>
                                        @endif
                                    </div>
                                    {{-- Tabel products tidak punya kolom description; baris
                                         deskripsi yang dulu ada di sini selalu kosong. --}}
                                    <div class="product-name">{{ $product->name }}</div>
                                </div>
                            </td>
                            <td><span class="code-badge">{{ $product->code }}</span></td>
                            <td>
                                @if($product->category)
                                    <span class="code-badge">{{ $product->category->name }}</span>
                                @else
                                    <span class="text-muted">-</span>
                                @endif
                            </td>
                            <td>
                                @include('products._variant-chips', ['product' => $product])
                            </td>
                            <td>
                                @php
                                    $stockClass = $product->stock_quantity > 5 ? 'active'
                                        : ($product->stock_quantity > 0 ? 'pending' : 'inactive');
                                @endphp
                                <span class="status-badge {{ $stockClass }} stock-total">{{ $product->stock_quantity }} unit</span>
                            </td>
                            <td><span class="price-amount">Rp {{ number_format($product->price, 0, ',', '.') }}</span></td>
                            <td>
                                <div class="d-flex gap-1">
                                    <a href="{{ route('products.show', $product) }}" class="action-btn view" title="Lihat detail">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                    <a href="{{ route('products.edit', $product) }}" class="action-btn edit" title="Edit produk">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    <a href="https://barcode.tec-it.com/en?data={{ urlencode($product->code) }}&code=Code128"
                                       target="_blank" rel="noopener" class="action-btn" title="Buat barcode">
                                        <i class="bi bi-upc-scan"></i>
                                    </a>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7">
                                <div class="empty-state">
                                    <i class="bi bi-box-seam empty-state-icon"></i>
                                    <div class="empty-state-title">Tidak ada produk ditemukan</div>
                                    <div class="empty-state-description">
                                        @if(request('search'))
                                            Tidak ada produk yang cocok dengan "{{ request('search') }}".
                                        @else
                                            Mulai dengan menambahkan produk pertama Anda.
                                        @endif
                                    </div>
                                    <a href="{{ route('products.create') }}" class="btn btn-primary">
                                        <i class="bi bi-plus-lg"></i>
                                        Tambah Produk
                                    </a>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    @if($products->hasPages())
        <div class="pagination-container">
            <div class="pagination-info">
                Menampilkan {{ $products->firstItem() }}–{{ $products->lastItem() }} dari {{ $products->total() }} produk
            </div>
            {{ $products->withQueryString()->links('vendor.pagination.bootstrap-5') }}
        </div>
    @endif

    @push('styles')
    <style>
        /* Angka stok disejajarkan antar baris supaya mudah dipindai. */
        .stock-total { font-variant-numeric: tabular-nums; }

        /* .action-btn di admin.css dirancang untuk <button>; sebagai <a> ia
           mewarisi garis bawah Bootstrap. Lihat catatan di laporan. */
        .products-table .action-btn { text-decoration: none; }

        /* Di layar sempit tabel digulir mendatar; tidak ada kolom yang disembunyikan
           karena kode dan stok per ukuran sama pentingnya saat stok opname. */
        @media (max-width: 768px) {
            .products-table .table { min-width: 46rem; }
        }
    </style>
    @endpush
</x-admin-layout>
