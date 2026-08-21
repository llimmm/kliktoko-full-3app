<x-admin-layout title="Tambah Ukuran">
    <div class="page-header">
        <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap">
            <div>
                <h1 class="page-title">Tambah Ukuran</h1>
                <p class="page-subtitle">Buat ukuran baru untuk varian produk</p>
            </div>
            <a href="{{ route('sizes.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left"></i>
                Kembali ke Ukuran
            </a>
        </div>
    </div>

    <div class="card">
        <div class="card-body p-4">
            <form action="{{ route('sizes.store') }}" method="POST">
                @csrf

                <div class="form-group">
                    <label class="form-label" for="name">Nama Ukuran</label>
                    <input type="text" class="form-control @error('name') is-invalid @enderror"
                           id="name" name="name" value="{{ old('name') }}"
                           placeholder="Contoh: Large" required autofocus>
                    @error('name')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                    <small class="form-text text-secondary">Kode dibuat otomatis dari nama ukuran.</small>
                </div>

                <div class="form-group">
                    <label class="form-label" for="description">Deskripsi</label>
                    <textarea class="form-control @error('description') is-invalid @enderror"
                              id="description" name="description" rows="4"
                              placeholder="Masukkan deskripsi ukuran">{{ old('description') }}</textarea>
                    @error('description')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                    <small class="form-text text-secondary">Opsional — untuk menjelaskan ukuran ini.</small>
                </div>

                <div class="d-flex justify-content-end gap-2 pt-3 border-top">
                    <a href="{{ route('sizes.index') }}" class="btn btn-secondary">Batal</a>
                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-check-lg"></i>
                        Simpan Ukuran
                    </button>
                </div>
            </form>
        </div>
    </div>
</x-admin-layout>
