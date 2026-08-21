<x-admin-layout title="Kategori">
    {{-- Pesan flash (success / error) dirender oleh layouts/admin.blade.php.
         Jangan tambahkan blok alert di sini — pesannya akan muncul dua kali. --}}

    <div class="page-header">
        <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap">
            <div>
                <h1 class="page-title">Manajemen Kategori</h1>
                <p class="page-subtitle">Kelola kategori produk</p>
            </div>
            <a href="{{ route('categories.create') }}" class="btn btn-primary">
                <i class="bi bi-plus-lg"></i>
                Tambah Kategori
            </a>
        </div>
    </div>

    {{-- Pencarian dikirim ke server: CategoryController@index sudah menyaring
         name dan slug. Filter di sisi klien hanya menyentuh 10 baris halaman
         berjalan, jadi kategori di halaman lain tidak akan pernah ketemu. --}}
    <form method="GET" action="{{ route('categories.index') }}" class="search-filter-container">
        <div class="search-box">
            <i class="bi bi-search search-icon"></i>
            <input type="text" name="search" id="searchInput"
                   placeholder="Cari kategori berdasarkan nama atau slug..."
                   value="{{ request('search') }}">
        </div>
        <button type="submit" class="btn btn-primary">
            <i class="bi bi-search"></i>
            Cari
        </button>
        @if(request('search'))
            <a href="{{ route('categories.index') }}" class="btn btn-secondary">
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
                        <th>Nama Kategori</th>
                        <th>Slug</th>
                        <th>Deskripsi</th>
                        <th>Dibuat</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($categories as $category)
                        <tr>
                            <td>
                                <div class="d-flex align-items-center gap-3">
                                    <div class="category-icon">
                                        <i class="bi bi-tag"></i>
                                    </div>
                                    <div class="category-name">{{ $category->name }}</div>
                                </div>
                            </td>
                            <td>
                                <span class="code-badge">{{ $category->slug }}</span>
                            </td>
                            <td>
                                <div class="category-description">
                                    {{ $category->description ?: 'Tidak ada deskripsi' }}
                                </div>
                            </td>
                            <td>
                                <div class="d-flex align-items-center gap-2">
                                    <i class="bi bi-calendar3"></i>
                                    <span>{{ $category->created_at->format('d M Y') }}</span>
                                </div>
                            </td>
                            <td>
                                <a href="{{ route('categories.edit', $category) }}"
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
                                    <i class="bi bi-tags empty-state-icon"></i>
                                    @if(request('search'))
                                        <div class="empty-state-title">Kategori tidak ditemukan</div>
                                        <div class="empty-state-description">
                                            Tidak ada kategori yang cocok dengan "{{ request('search') }}".
                                        </div>
                                        <a href="{{ route('categories.index') }}" class="btn btn-secondary">
                                            <i class="bi bi-arrow-counterclockwise"></i>
                                            Tampilkan semua kategori
                                        </a>
                                    @else
                                        <div class="empty-state-title">Belum ada kategori</div>
                                        <div class="empty-state-description">
                                            Mulai dengan menambahkan kategori pertama Anda.
                                        </div>
                                        <a href="{{ route('categories.create') }}" class="btn btn-primary">
                                            <i class="bi bi-plus-lg"></i>
                                            Tambah Kategori
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

    @if($categories->hasPages())
        <div class="pagination-container">
            <div class="pagination-info">
                Menampilkan {{ $categories->firstItem() }}–{{ $categories->lastItem() }}
                dari {{ $categories->total() }} kategori
            </div>
            {{-- appends() menjaga kata kunci pencarian tetap terbawa ke halaman 2 dst. --}}
            {{ $categories->appends(request()->query())->links('vendor.pagination.bootstrap-5') }}
        </div>
    @endif
</x-admin-layout>
