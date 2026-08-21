<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'start_time',
        'end_time',
        'late_tolerance',
        'salary_per_shift',
        'description'
    ];

    /**
     * start_time dan end_time adalah kolom TIME, bukan timestamp.
     *
     * Cast 'datetime' polos membuat Laravel menserialisasinya sebagai UTC:
     * 08:00 WIB keluar sebagai "2026-08-20T01:00:00.000000Z", dan app employee
     * menampilkan angka jamnya mentah-mentah — karyawan melihat shift pagi
     * mulai pukul 1 dini hari. Format eksplisit membuat JSON-nya "08:00:00"
     * tanpa pergeseran zona, sementara atributnya tetap Carbon sehingga
     * panel admin yang memakai ->format('H:i') tidak berubah.
     */
    protected $casts = [
        'start_time' => 'datetime:H:i:s',
        'end_time' => 'datetime:H:i:s',
        'late_tolerance' => 'integer'
    ];

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }
}