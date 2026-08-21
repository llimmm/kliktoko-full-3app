# API Sales Data - Kliktoko

Dokumentasi untuk API Sales Data pada aplikasi Kliktoko.

## Deskripsi

API ini menyediakan endpoint untuk mengakses data penjualan produk, termasuk detail transaksi seperti produk yang terjual, harga, metode pembayaran, status transaksi, dan karyawan yang melayani.

## Endpoint API

### 1. Get Sales History

Endpoint ini menampilkan riwayat penjualan dengan detail lengkap.

```
GET /api/sales-data
```

#### Parameter Query (Opsional)

- `date`: Filter berdasarkan tanggal tertentu (format: YYYY-MM-DD)
- `month`: Filter berdasarkan bulan (1-12)
- `year`: Filter berdasarkan tahun (default: tahun saat ini)
- `status`: Filter berdasarkan status transaksi (completed, pending, cancelled)

#### Contoh Response

```json
{
  "message": "Berhasil mendapatkan data penjualan",
  "data": [
    {
      "id": 1,
      "tanggal": "2023-06-15 14:30:25",
      "karyawan": "John Doe",
      "total_harga": "150.000",
      "metode_pembayaran": "QRIS",
      "status": "Selesai",
      "items": [
        {
          "nama_produk": "Kopi Arabica",
          "kode_produk": "KA001",
          "jumlah": 2,
          "harga_satuan": "25.000",
          "subtotal": "50.000"
        },
        {
          "nama_produk": "Croissant",
          "kode_produk": "CR001",
          "jumlah": 5,
          "harga_satuan": "20.000",
          "subtotal": "100.000"
        }
      ]
    }
  ]
}
```

### 2. Get Sales Summary

Endpoint ini menampilkan ringkasan penjualan yang dikelompokkan berdasarkan hari, bulan, atau produk.

```
GET /api/sales-summary
```

#### Parameter Query (Opsional)

- `group_by`: Pengelompokan data (day, month, product) - default: day
- `start_date`: Tanggal awal periode (format: YYYY-MM-DD) - default: awal bulan ini
- `end_date`: Tanggal akhir periode (format: YYYY-MM-DD) - default: hari ini

#### Contoh Response (group_by=day)

```json
{
  "message": "Berhasil mendapatkan ringkasan penjualan",
  "period": {
    "start_date": "2023-06-01",
    "end_date": "2023-06-30"
  },
  "data": [
    {
      "date": "2023-06-15",
      "total_sales": 5,
      "total_amount": "750.000",
      "items_sold": 25
    },
    {
      "date": "2023-06-16",
      "total_sales": 3,
      "total_amount": "450.000",
      "items_sold": 15
    }
  ]
}
```

#### Contoh Response (group_by=product)

```json
{
  "message": "Berhasil mendapatkan ringkasan penjualan",
  "period": {
    "start_date": "2023-06-01",
    "end_date": "2023-06-30"
  },
  "data": [
    {
      "product_name": "Kopi Arabica",
      "product_code": "KA001",
      "quantity_sold": 45,
      "total_amount": "1.125.000"
    },
    {
      "product_name": "Croissant",
      "product_code": "CR001",
      "quantity_sold": 32,
      "total_amount": "640.000"
    }
  ]
}
```

## Instalasi dan Penggunaan

1. Jalankan migrasi database untuk membuat tabel sales dan sale_items:

```bash
php artisan migrate
```

2. (Opsional) Jalankan seeder untuk mengisi data contoh:

```bash
php artisan db:seed --class=SalesSeeder
```

3. Akses API melalui endpoint yang tersedia dengan token autentikasi yang valid.

## Catatan

- Semua endpoint API memerlukan autentikasi menggunakan Laravel Sanctum.
- Format tanggal yang digunakan adalah YYYY-MM-DD.
- Status transaksi yang tersedia: completed (selesai), pending (menunggu pembayaran), cancelled (dibatalkan).
- Metode pembayaran yang tersedia: cash, transfer, qris.