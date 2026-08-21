<x-admin-layout title="Tambah Produk">
    <div class="page-header d-flex justify-content-between align-items-start gap-3">
        <div>
            <h1 class="page-title">Tambah Produk Baru</h1>
            <p class="page-subtitle">Buat produk baru untuk inventori</p>
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

    <form action="{{ route('products.store') }}" method="POST" enctype="multipart/form-data"
          class="product-form-layout">
        @csrf

        {{-- Panel pratinjau: hanya cermin dari isian di sebelah kanan. --}}
        <aside class="card product-preview">
            <h2 class="section-title">Pratinjau</h2>

            <div id="imagePreview" class="image-preview">
                <div class="image-preview-empty">
                    <i class="bi bi-image"></i>
                    <p>Pilih gambar untuk pratinjau</p>
                </div>
            </div>

            <dl class="preview-info">
                <div><dt>Nama</dt><dd id="previewName">-</dd></div>
                <div><dt>Harga</dt><dd id="previewPrice">-</dd></div>
                <div><dt>Stok</dt><dd id="previewStock">-</dd></div>
            </dl>
        </aside>

        <div class="card product-form">
            <div class="form-section">
                <h2 class="section-title">Informasi Dasar</h2>

                <div class="form-group">
                    <label class="form-label" for="name">Nama Produk</label>
                    <input type="text" class="form-control @error('name') is-invalid @enderror"
                           id="name" name="name" value="{{ old('name') }}"
                           placeholder="Misal: Kemeja Seragam Putih" required oninput="updatePreview()">
                    @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>

                <div class="form-group">
                    <label class="form-label" for="price">Harga (Rp)</label>
                    <input type="number" class="form-control @error('price') is-invalid @enderror"
                           id="price" name="price" value="{{ old('price') }}"
                           min="0" max="99999999.99" step="0.01"
                           placeholder="0" required oninput="updatePreview()">
                    @error('price')
                        <div class="invalid-feedback">{{ $message == 'The price must be between 0 and 99999999.99.' ? 'Harga tidak boleh melebihi Rp 99.999.999,99' : $message }}</div>
                    @enderror
                </div>

                <div class="form-group">
                    <label class="form-label" for="category_id">Kategori</label>
                    <select class="form-select @error('category_id') is-invalid @enderror"
                            id="category_id" name="category_id" required>
                        <option value="">Pilih Kategori</option>
                        @foreach(\App\Models\Category::all() as $category)
                            <option value="{{ $category->id }}" {{ old('category_id') == $category->id ? 'selected' : '' }}>
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
                    Isi jumlah stok untuk ukuran yang tersedia. Ukuran yang dikosongkan tidak akan dibuat.
                </p>

                <div class="size-stock-grid">
                    @foreach($sizes as $size)
                        <div class="size-stock-item">
                            <label class="size-stock-label" for="variant-{{ $size->id }}">{{ $size->code }}</label>
                            <input type="number"
                                   class="form-control size-stock-input"
                                   id="variant-{{ $size->id }}"
                                   name="variants[{{ $size->id }}]"
                                   value="{{ old('variants.' . $size->id) }}"
                                   min="0" placeholder="0" oninput="updatePreview()">
                        </div>
                    @endforeach
                </div>
                @error('variants')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>

            <div class="form-section">
                <h2 class="section-title">Gambar Produk</h2>

                <div class="form-group">
                    <label class="form-label" for="image">Upload Gambar</label>
                    <input type="file" class="form-control @error('image') is-invalid @enderror"
                           id="image" name="image" accept="image/*" required onchange="previewImage(this)">
                    @error('image')<div class="invalid-feedback">{{ $message }}</div>@enderror
                    <small class="form-text">Format JPG, PNG, atau GIF. Maksimal 2 MB.</small>
                </div>
            </div>

            <div class="d-flex justify-content-end mt-4 pt-4 border-top">
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-plus-circle"></i>
                    Buat Produk
                </button>
            </div>
        </div>
    </form>

    @push('styles')
    <style>
        .product-form-layout {
            display: grid;
            grid-template-columns: minmax(16rem, 1fr) 2fr;
            gap: 1.5rem;
            align-items: start;
        }

        .product-preview,
        .product-form { padding: 1.5rem; }

        /* .section-title, .form-section, .image-preview* kini ada di admin.css. */
        .image-preview { margin-bottom: 1.25rem; }

        .preview-info { margin: 0; }

        .preview-info > div {
            display: flex;
            justify-content: space-between;
            gap: 1rem;
            padding: 0.5rem 0;
            border-bottom: 1px solid var(--border-color);
        }

        .preview-info > div:last-child { border-bottom: 0; }

        .preview-info dt { font-size: 0.8125rem; color: var(--text-secondary); font-weight: 500; }
        .preview-info dd { margin: 0; font-size: 0.875rem; font-weight: 600; color: var(--text-primary); }

        @media (max-width: 992px) {
            .product-form-layout { grid-template-columns: 1fr; }
        }
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
            } else {
                preview.innerHTML =
                    '<div class="image-preview-empty"><i class="bi bi-image"></i><p>Pilih gambar untuk pratinjau</p></div>';
            }
        }

        function updatePreview() {
            const name = document.getElementById('name').value;
            const price = document.getElementById('price').value;

            // Stok total dijumlahkan dari seluruh ukuran yang diisi.
            let total = 0, terisi = 0;
            document.querySelectorAll('.size-stock-input').forEach(input => {
                if (input.value !== '') {
                    total += parseInt(input.value, 10) || 0;
                    terisi++;
                }
            });

            document.getElementById('previewName').textContent = name || '-';
            document.getElementById('previewPrice').textContent =
                price ? 'Rp ' + parseInt(price, 10).toLocaleString('id-ID') : '-';
            document.getElementById('previewStock').textContent =
                terisi ? `${total} unit / ${terisi} ukuran` : '-';
        }
    </script>
    @endpush
</x-admin-layout>
