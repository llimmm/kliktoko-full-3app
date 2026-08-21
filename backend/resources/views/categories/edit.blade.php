<x-admin-layout title="Edit Kategori">
    <div class="page-header">
        <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap">
            <div>
                <h1 class="page-title">Edit Kategori</h1>
                <p class="page-subtitle">Perbarui informasi kategori {{ $category->name }}</p>
            </div>
            <a href="{{ route('categories.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left"></i>
                Kembali ke Kategori
            </a>
        </div>
    </div>

    {{-- Error validasi datang dari $errors, bukan session flash, jadi layout
         tidak merendernya — blok ini bukan duplikat. --}}
    @if($errors->any())
        <div class="alert alert-danger">
            <strong><i class="bi bi-exclamation-triangle me-2"></i>Terjadi kesalahan:</strong>
            <ul class="mb-0 mt-2">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="edit-grid">
        <div class="card">
            <div class="card-body p-4 entity-summary">
                <div class="entity-avatar">
                    <i class="bi bi-tag-fill"></i>
                </div>
                <h2>{{ $category->name }}</h2>
                <span class="code-badge">{{ $category->slug }}</span>
                <div class="entity-meta">
                    <i class="bi bi-calendar3"></i>
                    Dibuat {{ $category->created_at->format('d M Y') }}
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-body p-4">
                <form action="{{ route('categories.update', $category) }}" method="POST">
                    @csrf
                    @method('PUT')

                    <div class="form-group">
                        <label class="form-label" for="name">Nama Kategori</label>
                        <input type="text" class="form-control @error('name') is-invalid @enderror"
                               id="name" name="name" value="{{ old('name', $category->name) }}"
                               placeholder="Masukkan nama kategori" required>
                        @error('name')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                        <small class="form-text text-secondary">Slug ikut diperbarui otomatis dari nama.</small>
                    </div>

                    <div class="form-group">
                        <label class="form-label" for="description">Deskripsi</label>
                        <textarea class="form-control @error('description') is-invalid @enderror"
                                  id="description" name="description" rows="4"
                                  placeholder="Masukkan deskripsi kategori">{{ old('description', $category->description) }}</textarea>
                        @error('description')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                        <small class="form-text text-secondary">Opsional — untuk menjelaskan isi kategori.</small>
                    </div>

                    <div class="d-flex justify-content-end gap-2 pt-3 border-top">
                        <a href="{{ route('categories.index') }}" class="btn btn-secondary">Batal</a>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-save"></i>
                            Simpan Perubahan
                        </button>
                    </div>
                </form>

                {{-- Form hapus berdiri sendiri: form HTML tidak boleh bersarang. --}}
                <div class="danger-zone">
                    <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap">
                        <div>
                            <div class="fw-semibold">Hapus kategori</div>
                            <small class="text-secondary">
                                Ditolak selama masih ada produk yang memakai kategori ini.
                            </small>
                        </div>
                        <form action="{{ route('categories.destroy', $category) }}" method="POST"
                              onsubmit="return confirm('Yakin ingin menghapus kategori ini secara permanen?')">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="btn btn-outline-danger">
                                <i class="bi bi-trash"></i>
                                Hapus Kategori
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Hanya aturan yang khas halaman ini. Kartu, tombol, form, dan badge
         datang dari admin.css — jangan tulis ulang di sini. --}}
    <style>
        .edit-grid {
            display: grid;
            grid-template-columns: minmax(240px, 1fr) 2fr;
            gap: 1.5rem;
            align-items: start;
        }

        .entity-summary {
            text-align: center;
        }

        .entity-avatar {
            width: 4rem;
            height: 4rem;
            margin: 0 auto 1.25rem;
            border-radius: 50%;
            background: var(--violet-600);
            color: var(--neutral-0);
            font-size: 1.5rem;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .entity-summary h2 {
            font-size: 1.25rem;
            font-weight: 600;
            color: var(--text-primary);
            margin-bottom: 0.75rem;
        }

        .entity-meta {
            margin-top: 1.25rem;
            padding-top: 1rem;
            border-top: 1px solid var(--border-color);
            color: var(--text-secondary);
            font-size: 0.8125rem;
        }

        .danger-zone {
            margin-top: 2rem;
            padding-top: 1.5rem;
            border-top: 1px solid var(--border-color);
        }

        @media (max-width: 992px) {
            .edit-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</x-admin-layout>
