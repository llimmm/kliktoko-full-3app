# Simoto Cashier

Aplikasi kasir untuk toko dengan fitur scanner barcode, printer thermal, dan manajemen produk.

## Fitur Utama

- **Scanner Barcode**: Support untuk USB scanner iware series X
- **Printer Thermal**: Cetak struk otomatis
- **Manajemen Produk**: CRUD produk dengan kategori
- **Order Management**: Sistem order dengan payment processing
- **History Transaksi**: Riwayat penjualan
- **Barcode Generator**: Generate barcode untuk produk

## Perbaikan Scanner (Update Terbaru)

### Masalah yang Diperbaiki:
1. **Scanner Page**: Sebelumnya scanner page menambahkan produk ke order list, sekarang hanya untuk testing scanner
2. **Homepage**: Sekarang homepage memiliki integrasi scanner untuk menambahkan produk ke order list
3. **Navigation**: Perbaikan navigation handling untuk mencegah aplikasi keluar saat back dari scanner page

### Cara Kerja Scanner:

#### Scanner Page (Testing)
- Halaman ini hanya untuk testing scanner hardware
- Tidak menambahkan produk ke order list
- Menampilkan hasil scan untuk debugging
- Ada tombol "Kembali ke Halaman Utama"

#### Homepage (Produksi)
- Scanner terintegrasi langsung di homepage
- Saat scan barcode, produk otomatis ditambahkan ke order list
- Ada indikator status scanner (Aktif/Nonaktif)
- Bisa toggle scanner on/off dengan klik icon

### Penggunaan Scanner:

1. **Untuk Testing Hardware**:
   - Buka menu "USB Scanner iware" dari drawer
   - Scan barcode untuk test hardware
   - Lihat hasil scan di halaman tersebut

2. **Untuk Menambah Produk ke Order**:
   - Pastikan scanner aktif di homepage (indikator hijau)
   - Scan barcode produk langsung di homepage
   - Produk akan otomatis ditambahkan ke order list
   - Muncul notifikasi "Added to cart: [nama produk]"

### Troubleshooting Scanner:

- Jika scanner tidak terdeteksi, cek koneksi USB
- Pastikan USB OTG support aktif di device
- Untuk Advan VX Neo, ikuti panduan USB settings di scanner page
- Jika produk tidak ditemukan, pastikan barcode sudah terdaftar di database

## Setup

### Prerequisites
- Flutter SDK
- Android Studio / VS Code
- USB Scanner (iware series X recommended)
- Thermal Printer (optional)

### Installation
1. Clone repository
2. Run `flutter pub get`
3. Run `flutter run`

## Dependencies

- `scan_gun`: Untuk USB scanner support
- `esc_pos_utils`: Untuk thermal printer
- `provider`: State management
- `http`: API calls
- `intl`: Internationalization

## License

MIT License
