<x-admin-layout title="Users">
    <div class="page-header">
        <h1 class="page-title">Manajemen User</h1>
        <p class="page-subtitle">Kelola akun dan akses sistem</p>
    </div>

    {{-- Pencarian diserahkan ke controller (?search=), bukan disaring di browser:
         filter JS hanya menyentuh 10 baris halaman yang sedang tampil. --}}
    <div class="search-filter-container">
        <form method="GET" action="{{ route('users.index') }}" class="search-box" role="search">
            <i class="bi bi-search search-icon"></i>
            <input type="search" name="search" value="{{ request('search') }}"
                   placeholder="Cari nama, email, atau kode…" aria-label="Cari user">
        </form>

        @if(request('search'))
            <a href="{{ route('users.index') }}" class="btn btn-outline-secondary">
                <i class="bi bi-x-lg"></i>
                Reset
            </a>
        @endif

        <a href="{{ route('users.create') }}" class="btn btn-primary ms-auto">
            <i class="bi bi-plus-lg"></i>
            Tambah User
        </a>
    </div>

    <div class="modern-table">
        <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Kode</th>
                        <th>Role</th>
                        <th>Status</th>
                        <th class="text-end">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($users as $user)
                        <tr>
                            <td>
                                <div class="d-flex align-items-center gap-3">
                                    <img src="https://ui-avatars.com/api/?name={{ urlencode($user->name) }}&background=ede9fe&color=7c3aed&size=72"
                                         alt="" width="36" height="36" class="rounded-circle flex-shrink-0">
                                    <div>
                                        <div class="user-name">{{ $user->name }}</div>
                                        <div class="user-email">{{ $user->email }}</div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <span class="code-badge">{{ $user->code ?? 'Belum diatur' }}</span>
                            </td>
                            <td>
                                {{-- Chip netral, bukan .status-badge: role bukan keadaan
                                     baik/buruk, jadi tidak boleh memakai warna semantik. --}}
                                <span class="role-badge {{ $user->role === 'admin' ? 'is-admin' : '' }}">
                                    {{ $user->role === 'admin' ? 'Admin' : 'Karyawan' }}
                                </span>
                            </td>
                            <td>
                                <span class="status-badge {{ $user->is_active ? 'active' : 'inactive' }}">
                                    <i class="bi {{ $user->is_active ? 'bi-check-circle' : 'bi-x-circle' }}"></i>
                                    {{ $user->is_active ? 'Aktif' : 'Nonaktif' }}
                                </span>
                            </td>
                            <td class="text-end">
                                <div class="dropdown">
                                    <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Aksi untuk {{ $user->name }}">
                                        <i class="bi bi-three-dots-vertical"></i>
                                    </button>
                                    <ul class="dropdown-menu dropdown-menu-end">
                                        <li><a class="dropdown-item" href="{{ route('users.show', $user) }}">
                                            <i class="bi bi-eye"></i>Lihat Detail
                                        </a></li>
                                        <li><a class="dropdown-item" href="{{ route('users.edit', $user) }}">
                                            <i class="bi bi-pencil"></i>Edit User
                                        </a></li>
                                        <li><hr class="dropdown-divider"></li>
                                        <li><button type="button" class="dropdown-item text-danger"
                                                    onclick="deleteUser({{ $user->id }}, @js($user->name))">
                                            <i class="bi bi-trash"></i>Hapus User
                                        </button></li>
                                    </ul>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5">
                                <div class="empty-state">
                                    <i class="bi bi-people empty-state-icon"></i>
                                    <div class="empty-state-title">Tidak ada user ditemukan</div>
                                    <div class="empty-state-description">
                                        {{ request('search') ? 'Coba kata kunci lain atau reset pencarian.' : 'Mulai dengan menambahkan user pertama Anda.' }}
                                    </div>
                                    <a href="{{ route('users.create') }}" class="btn btn-primary">
                                        <i class="bi bi-plus-lg"></i>
                                        Tambah User
                                    </a>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    @if($users->hasPages())
        <div class="pagination-container">
            <div class="pagination-info">
                Menampilkan {{ $users->firstItem() ?? 0 }}–{{ $users->lastItem() ?? 0 }} dari {{ $users->total() }} user
            </div>
            {{-- appends() menjaga ?search tetap terbawa ke halaman berikutnya. --}}
            {{ $users->appends(request()->query())->links('vendor.pagination.bootstrap-5') }}
        </div>
    @endif

    <div class="modal fade" id="deleteModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Hapus User</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Tutup"></button>
                </div>
                <div class="modal-body">
                    <p class="mb-1">Hapus user <strong id="deleteUserName"></strong> secara permanen?</p>
                    <small class="text-secondary">Tindakan ini tidak dapat dibatalkan.</small>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">Batal</button>
                    <form id="deleteForm" method="POST">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="btn btn-danger">
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
        function deleteUser(userId, userName) {
            document.getElementById('deleteUserName').textContent = userName;
            document.getElementById('deleteForm').action = '{{ url('users') }}/' + userId;
            bootstrap.Modal.getOrCreateInstance(document.getElementById('deleteModal')).show();
        }
    </script>
    @endpush
</x-admin-layout>
