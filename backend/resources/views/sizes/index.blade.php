<x-admin-layout title="Ukuran">
    {{-- Pesan flash (success / error) dirender oleh layouts/admin.blade.php.
         Jangan tambahkan blok alert di sini — pesannya akan muncul dua kali. --}}

    <div class="page-header">
        <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap">
            <div>
                <h1 class="page-title">Manajemen Ukuran</h1>
                <p class="page-subtitle">Kelola ukuran produk</p>
            </div>
            <a href="{{ route('sizes.create') }}" class="btn btn-primary">
                <i class="bi bi-plus-lg"></i>
                Tambah Ukuran
            </a>
        </div>
    </div>

    {{-- Pencarian dikirim ke server: SizeController@index sudah menyaring
         name dan code. Filter di sisi klien hanya menyentuh 10 baris halaman
         berjalan, jadi ukuran di halaman lain tidak akan pernah ketemu. --}}
    <form method="GET" action="{{ route('sizes.index') }}" class="search-filter-container">
        <div class="search-box">
            <i class="bi bi-search search-icon"></i>
            <input type="text" name="search" id="searchInput"
                   placeholder="Cari ukuran berdasarkan nama atau kode..."
                   value="{{ request('search') }}">
        </div>
        <button type="submit" class="btn btn-primary">
            <i class="bi bi-search"></i>
            Cari
        </button>
        @if(request('search'))
            <a href="{{ route('sizes.index') }}" class="btn btn-secondary">
                <i class="bi bi-x-lg"></i>
                Reset
            </a>
        @endif
    </form>

    <div class="modern-table">
        <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr>
                        <th>Nama Ukuran</th>
                        <th>Kode</th>
                        <th>Deskripsi</th>
                        <th>Dibuat</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($sizes as $size)
                        <tr>
                            <td>
                                <div class="d-flex align-items-center gap-3">
                                    <div class="size-icon">
                                        <i class="bi bi-rulers"></i>
                                    </div>
                                    <div class="size-name">{{ $size->name }}</div>
                                </div>
                            </td>
                            <td>
                                <span class="code-badge">{{ $size->code }}</span>
                            </td>
                            <td>
                                <div class="size-description">
                                    {{ $size->description ?: 'Tidak ada deskripsi' }}
                                </div>
                            </td>
                            <td>
                                <div class="d-flex align-items-center gap-2">
                                    <i class="bi bi-calendar3"></i>
                                    <span>{{ $size->created_at->format('d M Y') }}</span>
                                </div>
                            </td>
                            <td>
                                <a href="{{ route('sizes.edit', $size) }}"
                                   class="btn btn-sm btn-outline-secondary">
                                    <i class="bi bi-pencil"></i>
                                    Edit
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5">
                                <div class="empty-state">
                                    <i class="bi bi-rulers empty-state-icon"></i>
                                    @if(request('search'))
                                        <div class="empty-state-title">Ukuran tidak ditemukan</div>
                                        <div class="empty-state-description">
                                            Tidak ada ukuran yang cocok dengan "{{ request('search') }}".
                                        </div>
                                        <a href="{{ route('sizes.index') }}" class="btn btn-secondary">
                                            <i class="bi bi-arrow-counterclockwise"></i>
                                            Tampilkan semua ukuran
                                        </a>
                                    @else
                                        <div class="empty-state-title">Belum ada ukuran</div>
                                        <div class="empty-state-description">
                                            Mulai dengan menambahkan ukuran pertama Anda.
                                        </div>
                                        <a href="{{ route('sizes.create') }}" class="btn btn-primary">
                                            <i class="bi bi-plus-lg"></i>
                                            Tambah Ukuran
                                        </a>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    @if($sizes->hasPages())
        <div class="pagination-container">
            <div class="pagination-info">
                Menampilkan {{ $sizes->firstItem() }}–{{ $sizes->lastItem() }}
                dari {{ $sizes->total() }} ukuran
            </div>
            {{-- appends() menjaga kata kunci pencarian tetap terbawa ke halaman 2 dst. --}}
            {{ $sizes->appends(request()->query())->links('vendor.pagination.bootstrap-5') }}
        </div>
    @endif
</x-admin-layout>
