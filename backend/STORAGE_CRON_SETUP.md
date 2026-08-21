# Storage Symlink Cron Job Setup

## Masalah
Gambar produk tidak muncul karena symlink storage belum dibuat di Hostinger.

## Solusi
Setup cron job untuk membuat symlink storage secara otomatis.

## Langkah-langkah Setup

### 1. Upload Files
Upload file-file berikut ke root Laravel Anda:
- `cron_storage.php` (script PHP untuk cron job)
- `storage_symlink.sh` (script bash alternatif)

### 2. Set Permissions
```bash
chmod +x storage_symlink.sh
chmod 755 cron_storage.php
```

### 3. Test Manual
Jalankan script secara manual untuk test:
```bash
php cron_storage.php
```

### 4. Setup Cron Job di Hostinger

#### Cara 1: Via cPanel Cron Jobs
1. Login ke cPanel Hostinger
2. Cari "Cron Jobs"
3. Tambahkan cron job baru:
   - **Common Settings**: Every 5 minutes
   - **Command**: `php /home/username/public_html/cron_storage.php`
   - Ganti `username` dengan username Hostinger Anda

#### Cara 2: Via SSH (jika tersedia)
```bash
crontab -e
```
Tambahkan baris:
```
*/5 * * * * php /home/username/public_html/cron_storage.php
```

### 5. Alternative: Manual Setup
Jika cron job tidak bisa, jalankan manual:
```bash
# Via SSH
php /home/username/public_html/cron_storage.php

# Atau via browser (buat route khusus)
# Kunjungi: yourdomain.com/storage-setup
```

## Verifikasi
Setelah setup, cek apakah symlink berhasil:
1. Cek folder `public/storage/` sudah ada
2. Cek gambar produk sudah muncul
3. Cek log cron job di cPanel

## Troubleshooting

### Jika symlink gagal:
- Script akan otomatis copy file sebagai alternatif
- Cek permissions folder storage
- Pastikan path Laravel benar

### Jika gambar masih tidak muncul:
1. Cek URL gambar di browser
2. Pastikan file ada di `storage/app/public/`
3. Cek .htaccess di folder storage

## File Structure Setelah Setup
```
public_html/
├── public/
│   ├── storage/          # Symlink ke storage/app/public
│   │   ├── products/     # Gambar produk
│   │   └── .htaccess     # File akses
│   └── ...
├── storage/
│   └── app/
│       └── public/       # File asli
│           └── products/
└── cron_storage.php      # Script cron job
```

## Cron Job Schedule
- **Setiap 5 menit**: Untuk memastikan symlink selalu ada
- **Setiap upload**: Script akan copy file baru otomatis

## Keamanan
- Script hanya membuat symlink/copy file
- Tidak mengubah data atau konfigurasi
- Aman untuk dijalankan berkala
