<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sale extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'total_amount',
        'payment_method',
        'status',
        'notes'
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the user (employee) who processed this sale
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the items included in this sale
     */
    public function items(): HasMany
    {
        return $this->hasMany(SaleItem::class);
    }

    /**
     * Get the formatted payment method
     */
    public function getFormattedPaymentMethodAttribute(): string
    {
        $methods = [
            'cash' => 'Tunai',
            'qris' => 'QRIS',
            'transfer' => 'Transfer Bank'
        ];

        return $methods[$this->payment_method] ?? ($this->payment_method ?? 'Unknown');
    }

    /**
     * Get the formatted status
     */
    public function getFormattedStatusAttribute(): string
    {
        $statuses = [
            'completed' => 'Selesai',
            'pending' => 'Menunggu Pembayaran',
            'cancelled' => 'Dibatalkan'
        ];

        return $statuses[$this->status] ?? $this->status;
    }
}