<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Attendance extends Model
{
    protected $fillable = [
        'user_id',
        'shift_id',
        'date',
        'check_in',
        'check_out',
        'is_late',
        'check_in_photo'
    ];

    // 'date:Y-m-d' bukan 'date' polos — lihat penjelasan di App\Models\Leave.
    // check_in/check_out memang kolom TIMESTAMP, jadi cast datetime di bawah
    // sudah benar dan sengaja dibiarkan.
    protected $casts = [
        'date' => 'date:Y-m-d',
        'check_in' => 'datetime',
        'check_out' => 'datetime',
        'is_late' => 'boolean'
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($attendance) {
            if ($attendance->shift && $attendance->shift->late_threshold) {
                $checkInTime = $attendance->check_in->format('H:i:s');
                $lateThreshold = $attendance->shift->late_threshold->format('H:i:s');
                $attendance->is_late = $checkInTime > $lateThreshold;
            }
        });
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class);
    }
}