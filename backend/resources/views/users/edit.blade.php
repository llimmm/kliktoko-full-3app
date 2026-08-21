<x-admin-layout title="Edit User">
    <div class="page-header d-flex justify-content-between align-items-start gap-3 flex-wrap">
        <div>
            <h1 class="page-title">Edit User</h1>
            <p class="page-subtitle">Perbarui data {{ $user->name }}</p>
        </div>
        <div class="d-flex gap-2">
            <a href="{{ route('users.show', $user) }}" class="btn btn-outline-secondary">
                <i class="bi bi-eye"></i>
                Detail
            </a>
            <a href="{{ route('users.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left"></i>
                Kembali
            </a>
        </div>
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

    {{--
        Tiga form di halaman ini sengaja terpisah dan TIDAK boleh disarangkan —
        HTML melarang form bersarang, dan dulu form hapus yang bersarang membajak
        tombol simpan. Tombol simpan berada di luar #user-edit-form dan dikaitkan
        lewat atribut form=, begitu pula tombol status ke #user-status-form.
    --}}
    <div class="row g-4">
        <div class="col-lg-8">
            <div class="card">
                <div class="card-body">
                    <form id="user-edit-form" action="{{ route('users.update', $user) }}" method="POST">
                        @csrf
                        @method('PUT')

                        <div class="mb-3">
                            <label for="name" class="form-label">Nama Lengkap</label>
                            <input type="text" class="form-control @error('name') is-invalid @enderror"
                                   id="name" name="name" value="{{ old('name', $user->name) }}"
                                   placeholder="Masukkan nama lengkap" required>
                            @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        </div>

                        <div class="mb-3">
                            <label for="email" class="form-label">Email</label>
                            <input type="email" class="form-control @error('email') is-invalid @enderror"
                                   id="email" name="email" value="{{ old('email', $user->email) }}"
                                   placeholder="nama@kliktoko.id" required>
                            @error('email')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        </div>

                        <div class="mb-3">
                            <label for="code" class="form-label">Kode Unik</label>
                            <input type="text" class="form-control @error('code') is-invalid @enderror"
                                   id="code" name="code" value="{{ old('code', $user->code) }}"
                                   maxlength="4" pattern="[0-9]{4}" inputmode="numeric"
                                   placeholder="Contoh: 1234" required>
                            @error('code')<div class="invalid-feedback">{{ $message }}</div>@enderror
                            <div class="form-text">4 digit angka (0-9), dipakai karyawan untuk absensi.</div>
                        </div>

                        <div class="mb-3">
                            <label for="password" class="form-label">Password Baru</label>
                            <input type="password" class="form-control @error('password') is-invalid @enderror"
                                   id="password" name="password" placeholder="••••••">
                            @error('password')<div class="invalid-feedback">{{ $message }}</div>@enderror
                            <div class="form-text">Kosongkan bila password tidak diubah.</div>
                        </div>

                        <div class="mb-0">
                            <label for="role" class="form-label">Role</label>
                            <select class="form-select @error('role') is-invalid @enderror" id="role" name="role" required>
                                <option value="admin" {{ old('role', $user->role) === 'admin' ? 'selected' : '' }}>Admin</option>
                                <option value="karyawan" {{ old('role', $user->role) === 'karyawan' ? 'selected' : '' }}>Karyawan</option>
                            </select>
                            @error('role')<div class="invalid-feedback">{{ $message }}</div>@enderror
                            <div class="form-text">Hanya Admin yang dapat masuk panel ini.</div>
                        </div>
                    </form>
                </div>

                {{-- Di luar #user-edit-form; dikaitkan lewat atribut form=. --}}
                <div class="card-footer bg-transparent d-flex justify-content-end gap-2 py-3">
                    <a href="{{ route('users.index') }}" class="btn btn-light">Batal</a>
                    <button type="submit" form="user-edit-form" class="btn btn-primary">
                        <i class="bi bi-check-lg"></i>
                        Simpan Perubahan
                    </button>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="card mb-4">
                <div class="card-body text-center">
                    <div class="user-avatar d-inline-block mb-3">
                        <img src="https://ui-avatars.com/api/?name={{ urlencode($user->name) }}&background=ede9fe&color=7c3aed&size=160"
                             alt="" class="rounded-circle">
                    </div>
                    <div class="user-name fs-5">{{ $user->name }}</div>
                    <div class="user-email mb-3">{{ $user->email }}</div>
                    <div class="d-flex justify-content-center gap-2 flex-wrap">
                        <span class="code-badge">{{ $user->code ?? 'Belum diatur' }}</span>
                        <span class="status-badge {{ $user->is_active ? 'active' : 'inactive' }}">
                            <i class="bi {{ $user->is_active ? 'bi-check-circle' : 'bi-x-circle' }}"></i>
                            {{ $user->is_active ? 'Aktif' : 'Nonaktif' }}
                        </span>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="card-body">
                    <h2 class="h6 mb-2">Status Akun</h2>
                    <p class="text-secondary small mb-3">
                        {{ $user->is_active ? 'User dapat login dan mengakses sistem.' : 'User tidak dapat login.' }}
                    </p>

                    {{-- Form kosong, terpisah dari form edit. Tombolnya di bawah. --}}
                    <form id="user-status-form" action="{{ route('users.toggle-status', $user) }}" method="POST"
                          onsubmit="return confirm('{{ $user->is_active ? 'Nonaktifkan user ini?' : 'Aktifkan user ini?' }}')">
                        @csrf
                    </form>

                    <button type="submit" form="user-status-form" class="btn btn-outline-secondary w-100 justify-content-center">
                        <i class="bi bi-power"></i>
                        {{ $user->is_active ? 'Nonaktifkan User' : 'Aktifkan User' }}
                    </button>

                    <hr class="my-4">

                    <h2 class="h6 mb-2">Hapus User</h2>
                    <p class="text-secondary small mb-3">Data user hilang permanen dan tidak dapat dikembalikan.</p>

                    <form action="{{ route('users.destroy', $user) }}" method="POST"
                          onsubmit="return confirm('Hapus user {{ $user->name }} secara permanen?')">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="btn btn-outline-danger w-100 justify-content-center">
                            <i class="bi bi-trash"></i>
                            Hapus User
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    @push('scripts')
    <script>
        document.getElementById('code').addEventListener('input', function () {
            this.value = this.value.replace(/[^0-9]/g, '').slice(0, 4);
            this.setCustomValidity(
                this.value.length > 0 && !/^[0-9]{4}$/.test(this.value)
                    ? 'Kode harus terdiri dari 4 digit angka (0-9)'
                    : ''
            );
        });
    </script>
    @endpush
</x-admin-layout>
