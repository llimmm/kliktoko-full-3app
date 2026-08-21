# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Ekosistem tiga aplikasi

KlikToko adalah toko seragam/pakaian. Tiga aplikasi berbagi satu backend Laravel:

| Folder | Isi | Status |
|---|---|---|
| `backend/` | Laravel 12 — API + panel admin Blade | jalan, dikerjakan aktif |
| `mobile-cashier/` | Flutter `kasir_simoto` — POS tablet | tema selaras, ukuran per item jalan |
| `mobile-employee/` | Flutter `kliktoko` — absensi/stok/cuti/slip gaji, 15.318 baris | tema selaras, stok per ukuran jalan |
| `design-system/` | `tokens.dart`, disalin ke kedua app Flutter | dibuat |
| `_archive/` | backup asli + dump SQL + zip deploy | **jangan dihapus** |

`_archive/u612698043.20260805030532.tar.gz` adalah satu-satunya titik pulih penuh.

**Payroll, Leave, dan Region bukan kode mati.** Ketiganya pondasi untuk KlikToko Mobile (model GajiHub) dan sudah ada endpoint `/api/leave/*` yang dipanggil app employee. Jangan usulkan menghapusnya.

## Perintah

Menyalakan seluruh lingkungan lokal sekaligus — MariaDB, backend, dan jembatan USB ke tablet:

```powershell
powershell -ExecutionPolicy Bypass -File "start-local.ps1"
```

Skrip itu memakai `Start-Process`, jadi keduanya jadi jendela Windows sendiri dan **tidak ikut mati saat sesi Claude Code berakhir** — proses yang dijalankan langsung dari sesi selalu ikut dibersihkan. Aman dijalankan berulang; yang sudah hidup tidak dinyalakan dua kali. Hentikan dengan menutup dua jendela terminalnya.

Perintah satuan:

```bash
cd backend

C:/xampp/php/php.exe artisan serve                # http://127.0.0.1:8000
C:/xampp/php/php.exe artisan migrate:fresh --seed # bangun ulang dari nol
C:/xampp/php/php.exe artisan test --filter=NamaTest
C:/xampp/mysql/bin/mysql.exe -u root kliktoko -e "SELECT ..."
```

`composer install` **tidak diperlukan** — `vendor/` lengkap ikut backup. Composer sendiri tidak terpasang di mesin ini.

MariaDB perlu dinyalakan lebih dulu bila belum: jalankan `C:\xampp\mysql\bin\mysqld.exe` (atau `start-local.ps1` di atas). Database lokal bernama `kliktoko`, user `root` tanpa password.

**Seluruh data adalah dummy dan belum ada produksi.** Bebas di-wipe, tabel bebas diubah. `migrate:fresh --seed` menghasilkan lingkungan kerja lengkap; tidak perlu mengimpor dump apa pun (dump lama ada di `_archive/` sebagai arsip saja).

Akun hasil seeder: `admin` / `admin123`, karyawan `nadia`/`bagas`/`rizky`/`sari` dengan `karyawan123`. Karyawan **tidak bisa** masuk panel admin.

## Arsitektur backend

### Dua pintu masuk, tiga namespace controller

| Namespace | Auth | Konsumen |
|---|---|---|
| `App\Http\Controllers\API\*` | `auth:sanctum` | mobile cashier + employee |
| `App\Http\Controllers\Web\*` | session `auth` | panel admin Blade |
| `App\Http\Controllers\*` (root) | campuran — satu kelas melayani keduanya | `LocationController`, `TimezoneController`, `NotificationController` |

Controller di namespace root terdaftar di `routes/api.php` **dan** `routes/web.php`; satu perubahan mengenai mobile dan admin sekaligus.

### Stok per ukuran — jangan tulis ke kolom cermin

`product_variants` (produk × ukuran × stok) adalah **satu-satunya** sumber kebenaran stok. `products.stock_quantity` dan `products.size_id` sengaja dipertahankan sebagai cermin agar respons API lama tidak berubah bentuk untuk klien Flutter yang belum diperbarui.

Aturan yang tidak boleh dilanggar:
- Setiap perubahan stok varian **wajib** diikuti `Product::syncStockFromVariants()`.
- Jangan pernah `decrement` langsung ke `products.stock_quantity` — cermin akan menyimpang, lalu sinkronisasi berikutnya menghapus perubahan itu diam-diam.
- `sale_items.product_variant_id` nullable: itu jalur mundur untuk POS lama, bukan bug.
- Penjualan tanpa `product_variant_id` diterima hanya bila produk punya tepat satu ukuran; lebih dari itu ditolak agar tidak menebak.

### Timezone berbasis database

`config/app.php` menyebut `Asia/Jakarta`, tapi logika shift/absensi membaca baris aktif dari tabel `timezone_settings`:

```php
$now = Carbon::now(TimezoneSetting::getActive()->timezone);
```

**Jangan pakai `now()` polos** di kode shift, absensi, atau check-in — itu memakai timezone config dan merusak deployment WITA/WIT. `LocationSetting` memakai pola baris-aktif yang sama untuk geofence (Haversine).

### Warisan yang masih menunggu

- Tiga bentuk envelope API hidup berdampingan: `{status,...}`, `{success,...}`, dan `{message,data}` polos. Ikuti controller sekitarnya, jangan seragamkan sepihak — klien Flutter mem-parse tiap bentuk.
- App employee memanggil `/api/attendance/status`, Laravel mendaftarkannya sebagai `/api/shifts/status`.
- Dua mekanisme keterlambatan tumpang tindih: `late_tolerance` (dipakai `API\ShiftController::checkIn`) vs `late_threshold` (di `Attendance::boot()`).
- Tidak ada test sungguhan — hanya dua stub Laravel. Perubahan API divalidasi manual.

## Frontend admin

Bootstrap 5 dari CDN + CSS tulis tangan di `public/css/`. **Vite dan Tailwind adalah scaffolding mati** — tidak satu Blade pun memuat `@vite`; `npm run build` tidak berpengaruh apa pun.

Palet berasal dari `public/css/tokens.css`, dimuat **sebelum** `admin.css` dan sebelum stylesheet halaman. File itu memetakan ungu–abu–putih–hitam ke nama variabel lama (`--primary-color` dll) *dan* menimpa variabel Bootstrap (`--bs-primary`, `.btn-primary`), sehingga 1.200 baris CSS lama dan 27 view tidak perlu disentuh. Kembarannya untuk Flutter di `design-system/tokens.dart` — ubah salah satu, ubah keduanya.

Warna status stok (`--success`/`--warning`/`--danger`) sengaja **bukan** ungu: itu menyampaikan data, bukan merek.

Mode `bold` (border hitam tebal, shadow keras, target sentuh ≥56px) disiapkan untuk zona uang di app kasir, bukan untuk admin.

## Mobile employee

Alamat backend hanya ditulis di `lib/config/api_config.dart`. Ganti target tanpa menyentuh kode:

```bash
flutter run --dart-define=KLIKTOKO_API=http://192.168.1.10:8000
```

Bawaannya `10.0.2.2:8000` — alamat localhost milik host dari emulator Android. Untuk perangkat fisik pakai IP LAN.

Warna berasal dari `lib/theme/app_theme.dart`, nilainya dijaga sama dengan `design-system/tokens.dart`. Masih ada ~242 warna hardcoded tersisa, tapi yang bermakna sudah tersalur ke `AppTheme`.

**Kontras tidak boleh ditebak.** Ungu `#7C3AED` butuh teks putih (5,7:1; hitam hanya 3,7:1), sedangkan hijau `#16A34A` justru butuh teks hitam (6,4:1; putih hanya 3,3:1). `onPrimary: Colors.white` di `lightTheme` berlaku untuk ungu saja — jangan digeneralisasi ke warna status.

Karena itu `tokens.dart` punya dua kelompok warna status yang **tidak boleh ditukar**:

| Dipakai sebagai | Token | Alasan |
|---|---|---|
| isian chip / titik penanda, teks hitam di atasnya | `success` `warning` `danger` | 6,4:1 dan 6,6:1 terhadap hitam |
| teks berwarna di atas putih, atau latar yang memaksa teks putih (SnackBar) | `successText` `warningText` `dangerText` | kelompok pertama hanya 3,3:1 dan 3,2:1 di sana |

`Product.fromJson` membaca array `variants` dari `/api/products`; kalau kuncinya tidak ada, `variants` kosong dan layar jatuh ke total stok lama. `test/product_variant_test.dart` menjaga bentuk payload itu.

## Mobile cashier

POS tablet. **Provider, bukan GetX** — paket `get` dulu terpasang tapi nol pemakaian, jadi sudah dibuang; jangan menambahkannya kembali karena mengira app ini memakai GetX.

Alamat backend hanya di `lib/config/api_config.dart`, pola yang sama dengan app employee.

Tablet fisik lewat kabel USB tidak bisa memakai `10.0.2.2`. Pakai `adb reverse` — tablet menembus `localhost` milik host, tidak bergantung Wi-Fi sekamar maupun firewall:

```bash
"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" reverse tcp:8000 tcp:8000
flutter run --dart-define=KLIKTOKO_API=http://localhost:8000
```

`adb` tidak ada di PATH; jalurnya `%LOCALAPPDATA%\Android\Sdk\platform-toolsdb.exe`. Mesin ini tidak punya AVD sama sekali — verifikasi dilakukan di tablet fisik (Android 14, 1280×800 lanskap).

`targetSdkVersion` **tidak boleh turun di bawah 35**. Saat masih 33, Google Play Protect di Android 14 memblokir pemasangan dengan alasan "dibangun untuk versi lama Android" — build dan `flutter run` tampak berhasil, tapi app tidak pernah terpasang, dan pesannya hanya muncul di layar tablet.

Panel pesanan dibangun **inline di `home_page.dart`**, bukan widget terpisah. Dulu ada `widget/order_panel.dart` yang tidak pernah dirender siapa pun (bersama empat widget mati lain) — sudah dihapus, tapi perlu diingat kalau menambah widget baru: pastikan benar-benar dipakai sebelum merapikannya.

**Checkout wajib membawa ukuran.** `POST /api/sales` menolak item tanpa `product_variant_id` bila produknya punya ukuran lebih dari satu, dan seluruh katalog seeder memang begitu. Satu baris keranjang ditentukan oleh pasangan produk + ukuran (`OrderItem.lineKey`) — dulu dicocokkan lewat `product.name`, sehingga ukuran S dan L menyatu jadi satu baris dan stok yang berkurang jadi salah ukuran.

Pemilih ukuran (`widget/size_picker_sheet.dart`) hanya muncul bila memang ambigu; produk berukuran tunggal langsung masuk keranjang. Ukuran habis tetap ditampilkan tapi dinonaktifkan — kasir perlu bisa menjawab pembeli, dan menyembunyikannya membuat ukuran yang habis terlihat seperti ukuran yang tidak pernah ada.

Dua paket yang benar-benar dipakai: `scan_gun` (Dart murni, menyadap input keyboard dari scanner USB) dan `blue_thermal_printer` (**Android/iOS/macOS saja** — build Windows/web akan lolos kompilasi lalu melempar `MissingPluginException` saat mencetak).

Zona uang memakai `KtBold` dari `tokens.dart`: border hitam tebal, shadow keras, target sentuh ≥56px. Sisanya minimalism seperti admin dan employee.

Kasir menghasilkan barcode ISBN-13 dari ID produk, sedangkan backend tidak punya kolom `barcode` — scanner hanya cocok dengan barcode cetakan sendiri.

## Otorisasi admin

Route web dibungkus `['auth', 'admin']`. Middleware `admin` (`EnsureUserIsAdmin`) memeriksa role **dan** `is_active` di setiap request, lalu menghapus sesi bila gagal.

Ini penting: `Web\AuthController::login` juga memeriksa role, tapi itu hanya gerbang masuk. Tanpa middleware, sesi karyawan yang sudah terbentuk tetap membuka seluruh panel, dan user yang dinonaktifkan tetap masuk sampai sesinya berakhir. Jangan menambah route admin di luar grup itu.

## Menghapus data acuan

`categories.id` dirujuk `products.category_id` dengan **ON DELETE SET NULL** — database tidak menahan apa pun, menghapus kategori diam-diam mencopotnya dari produk. `sizes` dan `products` dijaga foreign key yang menolak, tapi tanpa penanganan hasilnya 500.

Ketiga controller (`Web\CategoryController`, `Web\SizeController`, `Web\ProductController`) memeriksa pemakaian lebih dulu dan menolak dengan pesan. Pesan flash dirender di `layouts/admin.blade.php`, bukan di tiap view — dulu tidak satu pun view index menampilkan `session('error')`, sehingga penolakan hilang tanpa jejak.

## Migrasi

`migrate` pada database kosong dulu selalu gagal; urutannya kacau dan satu migrasi kosong. Sudah diperbaiki dan diverifikasi menghasilkan skema identik dengan yang berjalan.

Kalau menambah migrasi, perhatikan bahwa `create_shifts_table` membuat `shifts`, `attendances`, **dan** `leaves` sekaligus, dan `create_categories_table` sekaligus mengubah `products`. Penamaan file menentukan urutan — pastikan tabel yang dirujuk sudah ada lebih dulu.
