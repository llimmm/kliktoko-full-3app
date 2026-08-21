<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notification extends Model
{
    protected $fillable = [
        'user_id',
        'type',
        'title',
        'message',
        'data',
        'is_read'
    ];

    protected $casts = [
        'data' => 'array',
        'is_read' => 'boolean'
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function markAsRead(): void
    {
        $this->update(['is_read' => true]);
    }

    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }

    public static function createStockNotification($product)
    {
        return self::create([
            'user_id' => 1, // Admin user ID
            'type' => 'low_stock',
            'title' => 'Stok Produk Menipis',
            'message' => "Stok {$product->name} tinggal {$product->stock} unit",
            'data' => ['product_id' => $product->id]
        ]);
    }

    public static function createAttendanceNotification($attendance)
    {
        $action = $attendance->type === 'check_in' ? 'masuk' : 'pulang';
        return self::create([
            'user_id' => 1,
            'type' => 'attendance',
            'title' => 'Aktivitas Kehadiran',
            'message' => "{$attendance->user->name} telah {$action} pada {$attendance->created_at->format('H:i')}",
            'data' => ['attendance_id' => $attendance->id]
        ]);
    }

    public static function createLeaveNotification($leave)
    {
        return self::create([
            'user_id' => 1,
            'type' => 'leave',
            'title' => 'Pengajuan Cuti',
            'message' => "{$leave->user->name} mengajukan cuti dari {$leave->start_date} sampai {$leave->end_date}",
            'data' => ['leave_id' => $leave->id]
        ]);
    }
}