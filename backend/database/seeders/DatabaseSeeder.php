<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\LocationSetting;
use App\Models\Product;
use App\Models\Shift;
use App\Models\Size;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Data pengembangan KlikToko.
 *
 * `php artisan migrate:fresh --seed` harus menghasilkan admin yang bisa login
 * dan cukup data untuk menilai tampilan — tanpa perlu mengimpor dump apa pun.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $sizes = $this->sizes();
        $categories = $this->categories();
        $this->shifts();
        $this->call([TimezoneSettingSeeder::class]);
        $this->location();
        $this->users();

        // Absensi, cuti, dan slip gaji: tabelnya sudah ada sejak awal tapi
        // selalu kosong, sehingga layar riwayat di app employee tidak pernah
        // bisa diuji dengan sungguhan. Dipisah supaya bisa dijalankan
        // sendiri dengan --class tanpa menyentuh SalesSeeder, yang memakai
        // Sale::create dan akan menggandakan riwayat kalau diulang.
        $this->call([EmployeeDataSeeder::class]);

        $this->products($sizes, $categories);

        // Penjualan dibuat terakhir: butuh karyawan dan varian produk.
        $this->call([SalesSeeder::class]);

        // SalesSeeder mengurangi stok saat membuat riwayat, jumlahnya acak.
        // Stok akhir ditetapkan di sini supaya tampilan selalu punya sebaran
        // yang sama: kebanyakan aman, beberapa menipis, satu habis.
        $this->finalStock($sizes);
    }

    private function sizes()
    {
        // Diurut dari kecil ke besar supaya tampil wajar di form stok per ukuran.
        return collect(['S', 'M', 'L', 'XL', 'XXL', 'XXXL'])
            ->mapWithKeys(fn ($code) => [
                $code => Size::firstOrCreate(['code' => $code], ['name' => $code]),
            ]);
    }

    private function categories()
    {
        return collect(['Seragam', 'Atasan', 'Celana', 'Dewasa', 'Anak-Anak'])
            ->mapWithKeys(fn ($name) => [
                $name => Category::firstOrCreate(['name' => $name], ['slug' => Str::slug($name)]),
            ]);
    }

    private function shifts(): void
    {
        // Jam shift dipakai API\ShiftController untuk mendeteksi shift dari waktu
        // check-in, jadi rentangnya tidak boleh saling tumpang tindih.
        $shifts = [
            ['name' => 'Shift Pagi', 'start_time' => '08:00:00', 'end_time' => '15:00:00'],
            ['name' => 'Shift Sore', 'start_time' => '15:00:01', 'end_time' => '22:00:00'],
        ];

        foreach ($shifts as $shift) {
            Shift::firstOrCreate(
                ['name' => $shift['name']],
                $shift + ['late_tolerance' => 15, 'salary_per_shift' => 75000],
            );
        }
    }

    private function location(): void
    {
        LocationSetting::firstOrCreate(
            ['name' => 'Toko KlikToko'],
            [
                'description' => 'Lokasi absensi karyawan',
                'latitude' => -6.753417,
                'longitude' => 110.843639,
                'radius_meters' => 50,
                'is_active' => true,
                'address' => 'Jl. Contoh No. 123',
                'city' => 'Jepara',
                'province' => 'Jawa Tengah',
            ],
        );
    }

    private function users(): void
    {
        User::firstOrCreate(
            ['name' => 'admin'],
            [
                'email' => 'admin@kliktoko.test',
                'code' => '1000',
                'password' => Hash::make('admin123'),
                'role' => 'admin',
                'is_active' => true,
            ],
        );

        foreach (['nadia', 'bagas', 'rizky', 'sari'] as $i => $name) {
            User::firstOrCreate(
                ['name' => $name],
                [
                    'email' => "{$name}@kliktoko.test",
                    'code' => (string) (2001 + $i),
                    'password' => Hash::make('karyawan123'),
                    'role' => 'karyawan',
                    'is_active' => true,
                ],
            );
        }
    }

    private function products($sizes, $categories): void
    {
        // stok ditulis sebagai kode ukuran => jumlah; inilah alasan
        // product_variants ada — satu model dijual dalam beberapa ukuran.
        foreach ($this->catalog() as [$name, $price, $category, $stock]) {
            $product = Product::firstOrCreate(
                ['name' => $name],
                [
                    'code' => 'PRD-' . str_pad((string) rand(1, 99999), 5, '0', STR_PAD_LEFT),
                    'price' => $price,
                    'stock_quantity' => 0,
                    'category_id' => $categories[$category]->id,
                    'size_id' => $sizes[array_key_first($stock)]->id,
                ],
            );

            foreach ($stock as $code => $qty) {
                $product->variants()->firstOrCreate(
                    ['size_id' => $sizes[$code]->id],
                    // Stok awal dilebihkan supaya SalesSeeder punya cukup bahan
                    // untuk 14 hari riwayat; angka akhirnya diatur di finalStock().
                    ['stock_quantity' => $qty + 60],
                );
            }

            $product->syncStockFromVariants();
        }
    }

    private function finalStock($sizes): void
    {
        foreach ($this->catalog() as [$name, , , $stock]) {
            $product = Product::where('name', $name)->first();

            foreach ($stock as $code => $qty) {
                $product->variants()
                    ->where('size_id', $sizes[$code]->id)
                    ->update(['stock_quantity' => $qty]);
            }

            $product->syncStockFromVariants();
        }
    }

    /**
     * Katalog produk beserta stok akhir per ukuran.
     *
     * Sebaran sengaja dibuat beragam agar penanda stok di admin ada isinya:
     * "Jaket Abu Sekolah" ukuran M habis, beberapa ukuran lain menipis (1-5).
     */
    private function catalog(): array
    {
        return [
            ['Seragam Pramuka', 75000, 'Seragam', ['S' => 12, 'M' => 20, 'L' => 18, 'XL' => 5]],
            ['Seragam SD Putih', 65000, 'Seragam', ['S' => 30, 'M' => 24, 'L' => 9]],
            ['Seragam SMP Biru', 82000, 'Seragam', ['M' => 14, 'L' => 11, 'XL' => 3]],
            ['Baju Wearpack', 120000, 'Dewasa', ['L' => 8, 'XL' => 15, 'XXL' => 6]],
            ['Jaket Abu Sekolah', 95000, 'Atasan', ['M' => 0, 'L' => 22, 'XL' => 17]],
            ['Celana Panjang Hitam', 88000, 'Celana', ['M' => 19, 'L' => 25, 'XL' => 4]],
            ['Kaos Olahraga Anak', 45000, 'Anak-Anak', ['S' => 40, 'M' => 33]],
        ];
    }
}
