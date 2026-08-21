{{--
    Ukuran beserta stoknya masing-masing.
    Dipakai di kartu dan tabel pada daftar produk, serta di halaman detail.
--}}
@if($product->variants->isNotEmpty())
    <div class="variant-chips">
        @foreach($product->variants->sortBy('size_id') as $variant)
            <span class="variant-chip {{ $variant->stock_quantity === 0 ? 'is-out' : ($variant->stock_quantity <= 5 ? 'is-low' : '') }}">
                <strong>{{ $variant->size?->code ?? '?' }}</strong>
                <span>{{ $variant->stock_quantity }}</span>
            </span>
        @endforeach
    </div>
@else
    <span class="text-muted">-</span>
@endif
