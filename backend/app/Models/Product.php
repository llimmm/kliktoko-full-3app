<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use HasFactory;

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Ukuran tunggal produk — peninggalan sebelum stok dipecah per ukuran.
     * Masih dipakai API lama; untuk data baru pakai variants().
     */
    public function size()
    {
        return $this->belongsTo(Size::class);
    }

    public function variants(): HasMany
    {
        return $this->hasMany(ProductVariant::class);
    }

    /**
     * Samakan products.stock_quantity dengan total stok seluruh varian.
     *
     * products.stock_quantity dipertahankan sebagai kolom cermin supaya respons
     * API yang sudah dipakai KlikToko Cashier / Mobile tidak berubah bentuk.
     * Panggil ini setiap kali stok varian berubah.
     */
    public function syncStockFromVariants(): void
    {
        $this->forceFill([
            'stock_quantity' => (int) $this->variants()->sum('stock_quantity'),
        ])->save();
    }

    protected $fillable = [
        'name',
        'price',
        'quantity',
        'code',
        'stock_quantity',
        'image_path',
        'size_id',
        'category_id',
    ];



    protected $casts = [
        'price' => 'decimal:2',
        'quantity' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public static function getAllowedSizes()
    {
        return Size::select('id', 'code')->get()->all();
    }
}