<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Menandai ukuran mana yang terjual pada tiap baris transaksi.
 *
 * Nullable dan tanpa backfill: transaksi lama memang tidak menyimpan ukuran,
 * dan klien POS yang belum dikirimi product_variant_id tetap bisa bertransaksi
 * lewat jalur lama (lihat API\SalesController::store).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sale_items', function (Blueprint $table) {
            $table->foreignId('product_variant_id')
                ->nullable()
                ->after('product_id')
                ->constrained()
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('sale_items', function (Blueprint $table) {
            $table->dropForeign(['product_variant_id']);
            $table->dropColumn('product_variant_id');
        });
    }
};
