<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        // Tabel untuk menyimpan transaksi penjualan
        Schema::create('sales', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained(); // Karyawan yang melayani
            $table->decimal('total_amount', 10, 2); // Total harga penjualan
            $table->enum('payment_method', ['cash', 'qris', 'transfer']); // Metode pembayaran
            $table->enum('status', ['completed', 'pending', 'cancelled'])->default('completed'); // Status transaksi
            $table->text('notes')->nullable(); // Catatan tambahan
            $table->timestamps();
        });

        // Tabel untuk menyimpan detail item yang terjual dalam transaksi
        Schema::create('sale_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_id')->constrained()->onDelete('cascade');
            $table->foreignId('product_id')->constrained();
            $table->integer('quantity');
            $table->decimal('price', 10, 2); // Harga per item saat dijual
            $table->decimal('subtotal', 10, 2); // Harga total untuk item ini (quantity * price)
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('sale_items');
        Schema::dropIfExists('sales');
    }
};