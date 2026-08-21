<x-admin-layout title="Restock">
    <div class="page-header">
        <div class="d-flex justify-content-between align-items-center">
            <div>
                <h1 class="page-title">Restock</h1>
                <p class="page-subtitle">Tambah stok per ukuran</p>
            </div>
            <a href="{{ route('products.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left me-2"></i>Kembali ke Produk
            </a>
        </div>
    </div>

    {{-- Pesan flash dirender oleh layouts/admin.blade.php, tidak diulang di sini. --}}

    <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
            <div class="card p-3">
                <div class="text-secondary small">Habis</div>
                <div class="fs-3 fw-semibold text-danger">{{ $outOfStockVariants->count() }}</div>
            </div>
        </div>
        <div class="col-6 col-md-3">
            <div class="card p-3">
                <div class="text-secondary small">Menipis (1–5)</div>
                <div class="fs-3 fw-semibold text-warning">{{ $lowStockVariants->count() }}</div>
            </div>
        </div>
        <div class="col-6 col-md-3">
            <div class="card p-3">
                <div class="text-secondary small">Aman</div>
                <div class="fs-3 fw-semibold">{{ $variants->where('stock_quantity', '>', 5)->count() }}</div>
            </div>
        </div>
        <div class="col-6 col-md-3">
            <div class="card p-3">
                <div class="text-secondary small">Total ukuran</div>
                <div class="fs-3 fw-semibold">{{ $variants->count() }}</div>
            </div>
        </div>
    </div>

    <form action="{{ route('products.bulk-restock') }}" method="POST">
        @csrf
        <div class="card">
            <div class="table-responsive">
                <table class="table align-middle mb-0">
                    <thead>
                        <tr>
                            <th>Produk</th>
                            <th>Ukuran</th>
                            <th class="text-end">Stok</th>
                            <th style="width: 10rem">Tambah</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($variants as $variant)
                            <tr>
                                <td>
                                    <div class="fw-medium">{{ $variant->product->name }}</div>
                                    <div class="text-secondary small">{{ $variant->product->code }}</div>
                                </td>
                                <td><span class="variant-chip"><strong>{{ $variant->size->code }}</strong></span></td>
                                <td class="text-end">
                                    @if($variant->stock_quantity === 0)
                                        <span class="badge bg-danger">Habis</span>
                                    @elseif($variant->stock_quantity <= 5)
                                        <span class="badge bg-warning text-dark">{{ $variant->stock_quantity }}</span>
                                    @else
                                        {{ $variant->stock_quantity }}
                                    @endif
                                </td>
                                <td>
                                    <input type="number" class="form-control"
                                           name="stock_add[{{ $variant->id }}]"
                                           min="1" max="1000" placeholder="0">
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="4" class="text-center text-secondary py-4">
                                    Belum ada produk dengan ukuran.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        @if($variants->isNotEmpty())
            <div class="d-flex justify-content-end mt-3">
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-arrow-clockwise me-2"></i>Update Stok
                </button>
            </div>
        @endif
    </form>
</x-admin-layout>
