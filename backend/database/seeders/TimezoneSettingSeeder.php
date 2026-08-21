<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\TimezoneSetting;

class TimezoneSettingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create default timezone settings
        $timezoneSettings = [
            [
                'timezone' => 'Asia/Jakarta',
                'timezone_name' => 'WIB',
                'utc_offset' => 7,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'timezone' => 'Asia/Makassar',
                'timezone_name' => 'WITA',
                'utc_offset' => 8,
                'is_active' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'timezone' => 'Asia/Jayapura',
                'timezone_name' => 'WIT',
                'utc_offset' => 9,
                'is_active' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($timezoneSettings as $setting) {
            TimezoneSetting::updateOrCreate(
                ['timezone' => $setting['timezone']],
                $setting
            );
        }
    }
}