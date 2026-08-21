<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Satu ukuran dari sebuah produk, beserta stoknya sendiri.
 */
class ProductVariant extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_id',
        'size_id',
        'stock_quantity',
    ];

    protected $casts = [
        'stock_quantity' => 'integer',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function size(): BelongsTo
    {
        return $this->belongsTo(Size::class);
    }

    /**
     * Kurangi stok varian secara aman.
     *
     * Dilakukan lewat satu UPDATE bersyarat, bukan read-modify-write, supaya dua
     * kasir yang menjual potongan stok terakhir secara bersamaan tidak dapat
     * mendorong stok menjadi minus. Mengembalikan false bila stok tidak cukup.
     */
    public function decrementStock(int $quantity): bool
    {
        $affected = static::whereKey($this->getKey())
            ->where('stock_quantity', '>=', $quantity)
            ->decrement('stock_quantity', $quantity);

        if ($affected === 0) {
            return false;
        }

        $this->refresh();

        return true;
    }
}
