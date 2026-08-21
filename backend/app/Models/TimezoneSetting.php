<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TimezoneSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'timezone',
        'timezone_name',
        'utc_offset',
        'is_active'
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'utc_offset' => 'integer'
    ];

    /**
     * Get the active timezone setting
     */
    public static function getActive()
    {
        return self::where('is_active', true)->first() ?? self::create([
            'timezone' => 'Asia/Jakarta',
            'timezone_name' => 'WIB',
            'utc_offset' => 7,
            'is_active' => true
        ]);
    }

    /**
     * Set as active timezone
     */
    public function setActive()
    {
        // Deactivate all other timezone settings
        self::where('id', '!=', $this->id)->update(['is_active' => false]);
        
        // Activate this timezone setting
        $this->update(['is_active' => true]);
    }

    /**
     * Get available timezone options
     */
    public static function getTimezoneOptions()
    {
        return [
            [
                'timezone' => 'Asia/Jakarta',
                'timezone_name' => 'WIB',
                'utc_offset' => 7,
                'description' => 'Waktu Indonesia Barat (GMT+7)'
            ],
            [
                'timezone' => 'Asia/Makassar',
                'timezone_name' => 'WITA',
                'utc_offset' => 8,
                'description' => 'Waktu Indonesia Tengah (GMT+8)'
            ],
            [
                'timezone' => 'Asia/Jayapura',
                'timezone_name' => 'WIT',
                'utc_offset' => 9,
                'description' => 'Waktu Indonesia Timur (GMT+9)'
            ]
        ];
    }
}