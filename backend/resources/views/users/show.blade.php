<x-admin-layout title="Detail User">
    <div class="page-header d-flex justify-content-between align-items-start gap-3 flex-wrap">
        <div>
            <h1 class="page-title">Detail User</h1>
            <p class="page-subtitle">Informasi lengkap {{ $user->name }}</p>
        </div>
        <div class="d-flex gap-2">
            <a href="{{ route('users.edit', $user) }}" class="btn btn-primary">
                <i class="bi bi-pencil"></i>
                Edit User
            </a>
            <a href="{{ route('users.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left"></i>
                Kembali
            </a>
        </div>
    </div>

    <div class="row g-4">
        <div class="col-lg-4">
            <div class="card">
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
        </div>

        <div class="col-lg-8">
            <div class="card">
                <div class="card-body">
                    <h2 class="h6 mb-3">Informasi User</h2>

                    <dl class="row mb-0">
                        <dt class="col-sm-4 text-secondary fw-normal py-2 border-bottom">Nama Lengkap</dt>
                        <dd class="col-sm-8 py-2 mb-0 border-bottom">{{ $user->name }}</dd>

                        <dt class="col-sm-4 text-secondary fw-normal py-2 border-bottom">Email</dt>
                        <dd class="col-sm-8 py-2 mb-0 border-bottom">{{ $user->email }}</dd>

                        <dt class="col-sm-4 text-secondary fw-normal py-2 border-bottom">Kode Unik</dt>
                        <dd class="col-sm-8 py-2 mb-0 border-bottom">
                            <span class="code-badge">{{ $user->code ?? 'Belum diatur' }}</span>
                        </dd>

                        <dt class="col-sm-4 text-secondary fw-normal py-2 border-bottom">Role</dt>
                        <dd class="col-sm-8 py-2 mb-0 border-bottom">
                            {{ $user->role === 'admin' ? 'Admin' : 'Karyawan' }}
                            <span class="text-secondary small">
                                — {{ $user->role === 'admin' ? 'dapat masuk panel admin' : 'hanya aplikasi mobile' }}
                            </span>
                        </dd>

                        <dt class="col-sm-4 text-secondary fw-normal py-2 border-bottom">Status Akun</dt>
                        <dd class="col-sm-8 py-2 mb-0 border-bottom">
                            <span class="status-badge {{ $user->is_active ? 'active' : 'inactive' }}">
                                <i class="bi {{ $user->is_active ? 'bi-check-circle' : 'bi-x-circle' }}"></i>
                                {{ $user->is_active ? 'Aktif' : 'Nonaktif' }}
                            </span>
                            <span class="text-secondary small">
                                — {{ $user->is_active ? 'dapat login' : 'tidak dapat login' }}
                            </span>
                        </dd>

                        <dt class="col-sm-4 text-secondary fw-normal py-2 border-bottom">Tanggal Dibuat</dt>
                        <dd class="col-sm-8 py-2 mb-0 border-bottom">{{ $user->created_at->format('d M Y H:i') }}</dd>

                        <dt class="col-sm-4 text-secondary fw-normal py-2">Update Terakhir</dt>
                        <dd class="col-sm-8 py-2 mb-0">{{ $user->updated_at->format('d M Y H:i') }}</dd>
                    </dl>
                </div>
            </div>
        </div>
    </div>
</x-admin-layout>
