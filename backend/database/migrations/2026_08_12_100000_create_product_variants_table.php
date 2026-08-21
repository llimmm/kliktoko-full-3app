<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Stok per ukuran.
 *
 * Sebelumnya satu baris `products` = satu ukuran, sehingga "Seragam Pramuka M"
 * dan "Seragam Pramuka L" harus dibuat sebagai dua produk terpisah dengan nama
 * dan foto yang diduplikasi. Tabel ini memindahkan stok ke level ukuran.
 *
 * `products.stock_quantity` sengaja TIDAK dihapus: kolom itu tetap dipertahankan
 * sebagai cermin dari SUM(product_variants.stock_quantity) supaya API yang sudah
 * dipakai KlikToko Cashier / KlikToko Mobile tidak berubah bentuk responsnya.
 * Lihat Product::syncStockFromVariants().
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_variants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('size_id')->constrained();
            $table->unsignedInteger('stock_quantity')->default(0);
            $table->timestamps();

            $table->unique(['product_id', 'size_id']);
        });

        // Backfill: tiap produk lama menjadi satu varian dengan ukuran & stok aslinya.
        $now = now();

        DB::table('products')
            ->whereNotNull('size_id')
            ->orderBy('id')
            ->chunkById(100, function ($products) use ($now) {
                $rows = [];

                foreach ($products as $product) {
                    $rows[] = [
                        'product_id' => $product->id,
                        'size_id' => $product->size_id,
                        'stock_quantity' => max(0, (int) $product->stock_quantity),
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                }

                if ($rows) {
                    DB::table('product_variants')->insert($rows);
                }
            });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_variants');
    }
};
