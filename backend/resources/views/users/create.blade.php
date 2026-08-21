<x-admin-layout title="Tambah User">
    <div class="page-header d-flex justify-content-between align-items-start gap-3 flex-wrap">
        <div>
            <h1 class="page-title">Tambah User</h1>
            <p class="page-subtitle">Buat akun baru untuk admin atau karyawan</p>
        </div>
        <a href="{{ route('users.index') }}" class="btn btn-outline-secondary">
            <i class="bi bi-arrow-left"></i>
            Kembali
        </a>
    </div>

    @if($errors->any())
        <div class="alert alert-danger">
            <strong>Periksa kembali isian berikut:</strong>
            <ul class="mb-0 mt-2">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="row g-4">
        <div class="col-lg-8">
            <div class="card">
                <div class="card-body">
                    <form id="user-create-form" action="{{ route('users.store') }}" method="POST">
                        @csrf

                        <div class="mb-3">
                            <label for="name" class="form-label">Nama Lengkap</label>
                            <input type="text" class="form-control @error('name') is-invalid @enderror"
                                   id="name" name="name" value="{{ old('name') }}"
                                   placeholder="Masukkan nama lengkap" required>
                            @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        </div>

                        <div class="mb-3">
                            <label for="email" class="form-label">Email</label>
                            <input type="email" class="form-control @error('email') is-invalid @enderror"
                                   id="email" name="email" value="{{ old('email') }}"
                                   placeholder="nama@kliktoko.id" required>
                            @error('email')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        </div>

                        <div class="mb-3">
                            <label for="code" class="form-label">Kode Unik</label>
                            <div class="input-group">
                                <input type="text" class="form-control @error('code') is-invalid @enderror"
                                       id="code" name="code" value="{{ old('code') }}"
                                       maxlength="4" pattern="[0-9]{4}" inputmode="numeric"
                                       placeholder="Contoh: 1234" required>
                                <button type="button" class="btn btn-outline-secondary" id="generateCode">
                                    <i class="bi bi-shuffle"></i>
                                    Acak
                                </button>
                            </div>
                            @error('code')<div class="invalid-feedback d-block">{{ $message }}</div>@enderror
                            <div class="form-text">4 digit angka (0-9), dipakai karyawan untuk absensi.</div>
                        </div>

                        <div class="mb-3">
                            <label for="password" class="form-label">Password</label>
                            <input type="password" class="form-control @error('password') is-invalid @enderror"
                                   id="password" name="password" minlength="6" required>
                            @error('password')<div class="invalid-feedback">{{ $message }}</div>@enderror
                            <div class="form-text">Minimal 6 karakter.</div>
                        </div>

                        <div class="mb-0">
                            <label for="role" class="form-label">Role</label>
                            <select class="form-select @error('role') is-invalid @enderror" id="role" name="role" required>
                                <option value="">Pilih role</option>
                                <option value="admin" {{ old('role') === 'admin' ? 'selected' : '' }}>Admin</option>
                                <option value="karyawan" {{ old('role') === 'karyawan' ? 'selected' : '' }}>Karyawan</option>
                            </select>
                            @error('role')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        </div>
                    </form>
                </div>

                <div class="card-footer bg-transparent d-flex justify-content-end gap-2 py-3">
                    <a href="{{ route('users.index') }}" class="btn btn-light">Batal</a>
                    <button type="submit" form="user-create-form" class="btn btn-primary">
                        <i class="bi bi-check-lg"></i>
                        Simpan User
                    </button>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="card">
                <div class="card-body">
                    <h2 class="h6 mb-3">Catatan</h2>
                    <ul class="mb-0 ps-3 text-secondary small">
                        <li class="mb-2"><strong>Admin</strong> dapat masuk panel ini. <strong>Karyawan</strong> hanya memakai aplikasi mobile.</li>
                        <li class="mb-2">Kode unik tidak boleh sama dengan user lain.</li>
                        <li>User baru langsung berstatus aktif.</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    @push('scripts')
    <script>
        (function () {
            const code = document.getElementById('code');

            document.getElementById('generateCode').addEventListener('click', function () {
                code.value = String(Math.floor(1000 + Math.random() * 9000));
                code.dispatchEvent(new Event('input'));
            });

            code.addEventListener('input', function () {
                this.value = this.value.replace(/[^0-9]/g, '').slice(0, 4);
                this.setCustomValidity(
                    this.value.length > 0 && !/^[0-9]{4}$/.test(this.value)
                        ? 'Kode harus terdiri dari 4 digit angka (0-9)'
                        : ''
                );
            });
        })();
    </script>
    @endpush
</x-admin-layout>
