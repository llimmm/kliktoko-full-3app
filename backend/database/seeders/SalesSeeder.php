<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class SalesSeeder extends Seeder
{
    public function run(): void
    {
        $cashiers = User::where('role', 'karyawan')->get();
        $variants = ProductVariant::with('product')->where('stock_quantity', '>', 0)->get();

        if ($cashiers->isEmpty() || $variants->isEmpty()) {
            $this->command->warn('Butuh karyawan dan varian produk lebih dulu; SalesSeeder dilewati.');

            return;
        }

        // 14 hari terakhir supaya dashboard "hari ini" ikut terisi.
        for ($day = 0; $day < 14; $day++) {
            $date = Carbon::now()->subDays($day);

            foreach (range(1, rand(4, 12)) as $ignored) {
                $saleTime = $date->copy()->setTime(rand(8, 20), rand(0, 59));

                $sale = Sale::create([
                    'user_id' => $cashiers->random()->id,
                    'total_amount' => 0,
                    'payment_method' => ['cash', 'qris', 'transfer'][rand(0, 2)],
                    'status' => 'completed',
                    'notes' => null,
                    'created_at' => $saleTime,
                    'updated_at' => $saleTime,
                ]);

                $total = 0;
                $touched = [];

                foreach ($variants->random(rand(1, 3)) as $variant) {
                    // Tidak pernah menjual melebihi stok — kalau tidak, data
                    // dev langsung melanggar aturan yang dijaga POS.
                    $qty = min(rand(1, 3), $variant->stock_quantity);

                    if ($qty < 1) {
                        continue;
                    }

                    $price = $variant->product->price;
                    $subtotal = $qty * $price;

                    SaleItem::create([
                        'sale_id' => $sale->id,
                        'product_id' => $variant->product_id,
                        'product_variant_id' => $variant->id,
                        'quantity' => $qty,
                        'price' => $price,
                        'subtotal' => $subtotal,
                        'created_at' => $saleTime,
                        'updated_at' => $saleTime,
                    ]);

                    $variant->decrement('stock_quantity', $qty);
                    $total += $subtotal;
                    $touched[$variant->product_id] = $variant->product;
                }

                $sale->update(['total_amount' => $total]);

                foreach ($touched as $product) {
                    $product->syncStockFromVariants();
                }
            }
        }

        $this->command->info('Penjualan 14 hari terakhir dibuat.');
    }
}
