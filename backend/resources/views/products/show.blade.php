<x-admin-layout title="Detail Produk">
    <div class="page-header d-flex justify-content-between align-items-start gap-3">
        <div>
            <h1 class="page-title">{{ $product->name }}</h1>
            <p class="page-subtitle">
                <span class="code-badge">{{ $product->code }}</span>
                @if($product->category)
                    <span class="code-badge">{{ $product->category->name }}</span>
                @endif
            </p>
        </div>
        <div class="d-flex gap-2">
            <a href="{{ route('products.edit', $product) }}" class="btn btn-primary">
                <i class="bi bi-pencil"></i>
                Edit Produk
            </a>
            <a href="{{ route('products.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left"></i>
                Kembali ke Produk
            </a>
        </div>
    </div>

    <div class="product-detail-layout">
        <div class="card product-photo">
            @if($product->image_path)
                <img src="{{ Storage::url($product->image_path) }}" alt="{{ $product->name }}">
            @else
                <div class="product-photo-empty">
                    <i class="bi bi-image"></i>
                    <p>Belum ada gambar</p>
                </div>
            @endif
        </div>

        <div class="card product-detail">
            <div class="detail-block">
                <h2 class="section-title">Harga</h2>
                <p class="detail-price">Rp {{ number_format($product->price, 0, ',', '.') }}</p>
            </div>

            {{--
                Stok per ukuran adalah sumber kebenaran (product_variants);
                total di bawahnya hanya cermin dari penjumlahan varian.
            --}}
            <div class="detail-block">
                <h2 class="section-title">Stok per Ukuran</h2>
                @include('products._variant-chips', ['product' => $product])

                @php
                    $stockClass = $product->stock_quantity > 5 ? 'active'
                        : ($product->stock_quantity > 0 ? 'pending' : 'inactive');
                @endphp
                <p class="detail-stock-total mt-3">
                    Total <span class="status-badge {{ $stockClass }}">{{ $product->stock_quantity }} unit</span>
                    @if($product->stock_quantity === 0)
                        <span class="text-muted">— stok habis, perlu restock segera.</span>
                    @elseif($product->stock_quantity <= 5)
                        <span class="text-muted">— stok menipis, pertimbangkan restock.</span>
                    @endif
                </p>
            </div>

            <div class="detail-block">
                <h2 class="section-title">Informasi Lain</h2>
                <dl class="detail-meta">
                    <div><dt>Kode Produk</dt><dd>{{ $product->code }}</dd></div>
                    <div><dt>Kategori</dt><dd>{{ $product->category->name ?? 'Tanpa kategori' }}</dd></div>
                    <div><dt>Jumlah Ukuran</dt><dd>{{ $product->variants->count() }}</dd></div>
                    <div><dt>Dibuat</dt><dd>{{ $product->created_at->format('d M Y H:i') }}</dd></div>
                    <div><dt>Terakhir Diubah</dt><dd>{{ $product->updated_at->format('d M Y H:i') }}</dd></div>
                </dl>
            </div>

            <div class="mt-4 pt-4 border-top">
                <form action="{{ route('products.destroy', $product) }}" method="POST"
                      onsubmit="return confirm('Yakin ingin menghapus produk ini secara permanen?')">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="btn btn-outline-danger">
                        <i class="bi bi-trash"></i>
                        Hapus Produk
                    </button>
                </form>
            </div>
        </div>
    </div>

    @push('styles')
    <style>
        .product-detail-layout {
            display: grid;
            grid-template-columns: minmax(16rem, 1fr) 2fr;
            gap: 1.5rem;
            align-items: start;
        }

        .product-photo { overflow: hidden; }
        .product-photo img { width: 100%; aspect-ratio: 1; object-fit: cover; display: block; }

        .product-photo-empty {
            aspect-ratio: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            color: var(--text-secondary);
            background: var(--light-bg);
        }

        .product-photo-empty i { font-size: 2.5rem; }
        .product-photo-empty p { margin: 0.5rem 0 0; font-size: 0.8125rem; }

        .product-detail { padding: 1.5rem; }

        .section-title {
            font-size: 0.8125rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--text-secondary);
            margin-bottom: 0.75rem;
        }

        .detail-block + .detail-block {
            margin-top: 1.5rem;
            padding-top: 1.5rem;
            border-top: 1px solid var(--border-color);
        }

        .detail-price {
            font-size: 1.75rem;
            font-weight: 700;
            color: var(--primary-color);
            margin: 0;
            font-variant-numeric: tabular-nums;
        }

        .detail-stock-total { font-size: 0.875rem; margin-bottom: 0; }

        .detail-meta {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(12rem, 1fr));
            gap: 1rem;
            margin: 0;
        }

        .detail-meta dt { font-size: 0.75rem; color: var(--text-secondary); font-weight: 500; }
        .detail-meta dd { margin: 0.125rem 0 0; font-size: 0.875rem; color: var(--text-primary); font-weight: 500; }

        @media (max-width: 992px) {
            .product-detail-layout { grid-template-columns: 1fr; }
        }
    </style>
    @endpush
</x-admin-layout>
