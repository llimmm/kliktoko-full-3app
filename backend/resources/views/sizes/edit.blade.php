<x-admin-layout title="Edit Ukuran">
    <div class="page-header">
        <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap">
            <div>
                <h1 class="page-title">Edit Ukuran</h1>
                <p class="page-subtitle">Perbarui informasi ukuran {{ $size->name }}</p>
            </div>
            <a href="{{ route('sizes.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left"></i>
                Kembali ke Ukuran
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
                    <i class="bi bi-rulers"></i>
                </div>
                <h2>{{ $size->name }}</h2>
                <span class="code-badge">{{ $size->code }}</span>
                <div class="entity-meta">
                    <i class="bi bi-calendar3"></i>
                    Dibuat {{ $size->created_at->format('d M Y') }}
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-body p-4">
                <form action="{{ route('sizes.update', $size) }}" method="POST">
                    @csrf
                    @method('PUT')

                    <div class="form-group">
                        <label class="form-label" for="name">Nama Ukuran</label>
                        <input type="text" class="form-control @error('name') is-invalid @enderror"
                               id="name" name="name" value="{{ old('name', $size->name) }}"
                               placeholder="Masukkan nama ukuran" required>
                        @error('name')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                        <small class="form-text text-secondary">Kode ikut diperbarui otomatis dari nama.</small>
                    </div>

                    <div class="form-group">
                        <label class="form-label" for="description">Deskripsi</label>
                        <textarea class="form-control @error('description') is-invalid @enderror"
                                  id="description" name="description" rows="4"
                                  placeholder="Masukkan deskripsi ukuran">{{ old('description', $size->description) }}</textarea>
                        @error('description')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                        <small class="form-text text-secondary">Opsional — untuk menjelaskan ukuran ini.</small>
                    </div>

                    <div class="d-flex justify-content-end gap-2 pt-3 border-top">
                        <a href="{{ route('sizes.index') }}" class="btn btn-secondary">Batal</a>
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
                            <div class="fw-semibold">Hapus ukuran</div>
                            <small class="text-secondary">
                                Ditolak selama masih ada varian produk yang memakai ukuran ini.
                            </small>
                        </div>
                        <form action="{{ route('sizes.destroy', $size) }}" method="POST"
                              onsubmit="return confirm('Yakin ingin menghapus ukuran ini secara permanen?')">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="btn btn-outline-danger">
                                <i class="bi bi-trash"></i>
                                Hapus Ukuran
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
