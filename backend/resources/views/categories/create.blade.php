<x-admin-layout title="Tambah Kategori">
    <div class="page-header">
        <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap">
            <div>
                <h1 class="page-title">Tambah Kategori</h1>
                <p class="page-subtitle">Buat kategori baru untuk mengelompokkan produk</p>
            </div>
            <a href="{{ route('categories.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left"></i>
                Kembali ke Kategori
            </a>
        </div>
    </div>

    <div class="card">
        <div class="card-body p-4">
            <form action="{{ route('categories.store') }}" method="POST">
                @csrf

                <div class="form-group">
                    <label class="form-label" for="name">Nama Kategori</label>
                    <input type="text" class="form-control @error('name') is-invalid @enderror"
                           id="name" name="name" value="{{ old('name') }}"
                           placeholder="Contoh: Seragam Sekolah" required autofocus>
                    @error('name')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                    <small class="form-text text-secondary">Slug dibuat otomatis dari nama kategori.</small>
                </div>

                <div class="form-group">
                    <label class="form-label" for="description">Deskripsi</label>
                    <textarea class="form-control @error('description') is-invalid @enderror"
                              id="description" name="description" rows="4"
                              placeholder="Masukkan deskripsi kategori">{{ old('description') }}</textarea>
                    @error('description')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                    <small class="form-text text-secondary">Opsional — untuk menjelaskan isi kategori.</small>
                </div>

                <div class="d-flex justify-content-end gap-2 pt-3 border-top">
                    <a href="{{ route('categories.index') }}" class="btn btn-secondary">Batal</a>
                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-check-lg"></i>
                        Simpan Kategori
                    </button>
                </div>
            </form>
        </div>
    </div>
</x-admin-layout>
