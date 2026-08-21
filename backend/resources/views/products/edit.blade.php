<x-admin-layout title="Edit Produk">
    <div class="page-header d-flex justify-content-between align-items-start gap-3">
        <div>
            <h1 class="page-title">Edit Produk</h1>
            <p class="page-subtitle">{{ $product->name }} &middot; {{ $product->code }}</p>
        </div>
        <a href="{{ route('products.index') }}" class="btn btn-outline-secondary">
            <i class="bi bi-arrow-left"></i>
            Kembali ke Produk
        </a>
    </div>

    @if($errors->any())
        <div class="alert alert-danger">
            <strong>Terjadi kesalahan:</strong>
            <ul class="mb-0 mt-2">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="card product-form">
        <form id="product-edit-form" action="{{ route('products.update', $product) }}" method="POST" enctype="multipart/form-data">
            @csrf
            @method('PUT')

            <div class="form-section">
                <h2 class="section-title">Informasi Dasar</h2>

                <div class="form-group">
                    <label class="form-label" for="name">Nama Produk</label>
                    <input type="text" class="form-control @error('name') is-invalid @enderror"
                           id="name" name="name" value="{{ old('name', $product->name) }}" required>
                    @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>

                <div class="form-group">
                    <label class="form-label" for="price">Harga (Rp)</label>
                    <input type="number" class="form-control @error('price') is-invalid @enderror"
                           id="price" name="price" value="{{ old('price', $product->price) }}"
                           min="0" step="0.01" required>
                    @error('price')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>

                <div class="form-group">
                    <label class="form-label" for="category_id">Kategori</label>
                    <select class="form-select @error('category_id') is-invalid @enderror"
                            id="category_id" name="category_id" required>
                        <option value="">Pilih Kategori</option>
                        @foreach(\App\Models\Category::all() as $category)
                            <option value="{{ $category->id }}" {{ old('category_id', $product->category_id) == $category->id ? 'selected' : '' }}>
                                {{ $category->name }}
                            </option>
                        @endforeach
                    </select>
                    @error('category_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
            </div>

            <div class="form-section">
                <h2 class="section-title">Stok per Ukuran</h2>
                <p class="form-text mb-3">
                    Kosongkan ukuran yang tidak lagi dijual — varian itu akan dihapus.
                    Total stok produk dihitung otomatis dari seluruh ukuran.
                </p>

                <div class="size-stock-grid">
                    @foreach($sizes as $size)
                        <div class="size-stock-item">
                            <label class="size-stock-label" for="variant-{{ $size->id }}">{{ $size->code }}</label>
                            <input type="number"
                                   class="form-control size-stock-input"
                                   id="variant-{{ $size->id }}"
                                   name="variants[{{ $size->id }}]"
                                   value="{{ old('variants.' . $size->id, $stockBySize[$size->id] ?? null) }}"
                                   min="0" placeholder="0">
                        </div>
                    @endforeach
                </div>
                @error('variants')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>

            <div class="form-section">
                <h2 class="section-title">Gambar Produk</h2>

                <div id="imagePreview" class="image-preview">
                    @if($product->image_path)
                        <img src="{{ Storage::url($product->image_path) }}" alt="{{ $product->name }}">
                    @else
                        <div class="image-preview-empty">
                            <i class="bi bi-image"></i>
                            <p>Belum ada gambar</p>
                        </div>
                    @endif
                </div>

                <div class="form-group">
                    <label class="form-label" for="image">Ganti Gambar</label>
                    <input type="file" class="form-control @error('image') is-invalid @enderror"
                           id="image" name="image" accept="image/*" onchange="previewImage(this)">
                    @error('image')<div class="invalid-feedback">{{ $message }}</div>@enderror
                    <small class="form-text">Kosongkan untuk mempertahankan gambar saat ini.</small>
                </div>
            </div>
        </form>

        {{--
            Form hapus HARUS berada di luar form edit: HTML tidak mengizinkan
            form bersarang, dan browser menutup form luar begitu menemui form
            dalam — dulu itu membuat tombol "Update Produk" ikut memicu hapus.
            Tombol simpan dikaitkan kembali lewat atribut form=.
        --}}
        <div class="d-flex justify-content-between align-items-center gap-3 mt-4 pt-4 border-top">
            <form action="{{ route('products.destroy', $product) }}" method="POST"
                  onsubmit="return confirm('Yakin ingin menghapus produk ini secara permanen?')">
                @csrf
                @method('DELETE')
                <button type="submit" class="btn btn-outline-danger">
                    <i class="bi bi-trash"></i>
                    Hapus Produk
                </button>
            </form>
            <button type="submit" form="product-edit-form" class="btn btn-primary">
                <i class="bi bi-check2-circle"></i>
                Update Produk
            </button>
        </div>
    </div>

    @push('styles')
    <style>
        .product-form { padding: 1.5rem; max-width: 56rem; }

        /* .section-title, .form-section, .image-preview* kini ada di admin.css. */
        .image-preview { max-width: 15rem; margin-bottom: 1.25rem; }
    </style>
    @endpush

    @push('scripts')
    <script>
        function previewImage(input) {
            const preview = document.getElementById('imagePreview');

            if (input.files && input.files[0]) {
                const reader = new FileReader();
                reader.onload = (e) => {
                    const img = document.createElement('img');
                    img.alt = 'Pratinjau';
                    img.src = e.target.result;
                    preview.replaceChildren(img);
                };
                reader.readAsDataURL(input.files[0]);
            }
        }
    </script>
    @endpush
</x-admin-layout>
