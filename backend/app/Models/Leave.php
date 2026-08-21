<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Leave extends Model
{
    protected $fillable = [
        'user_id',
        'date',
        'status',
        'reason'
    ];

    /**
     * Kolom DATE, bukan timestamp.
     *
     * Cast 'date' polos membuat Laravel menserialisasinya sebagai UTC:
     * cuti 2026-08-25 keluar sebagai "2026-08-24T17:00:00.000000Z" — mundur
     * satu hari. Yang bergeser di sini nomor harinya, bukan sekadar jam, dan
     * nyaris tidak ada yang menyadarinya sampai ada karyawan protes cutinya
     * tercatat di tanggal yang salah. Format eksplisit membuat JSON-nya
     * "2026-08-25" sementara atributnya tetap Carbon.
     */
    protected $casts = [
        'date' => 'date:Y-m-d'
    ];

    /** Status yang dikenali. Kolomnya varchar biasa, jadi tidak ada penjaga di database. */
    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public static function getRemainingLeaves(int $userId, string $month): int
    {
        $totalLeaves = self::where('user_id', $userId)
            ->whereMonth('date', $month)
            ->where('status', 'approved')
            ->count();

        return 4 - $totalLeaves;
    }
}