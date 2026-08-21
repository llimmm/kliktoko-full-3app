<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Kode 4 digit untuk login cepat di POS (GET /api/users/by-code).
 *
 * File ini sebelumnya kosong: kolomnya ditambahkan langsung ke database
 * produksi dan migrasinya tidak pernah diisi, sehingga database yang dibangun
 * dari nol kehilangan kolom ini. Isinya sekarang mengikuti kolom yang berjalan.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'code')) {
                $table->string('code', 4)->nullable()->unique()->after('email');
            }

            // Dipakai API\ShiftController saat check-in/check-out.
            if (!Schema::hasColumn('users', 'is_checked_in')) {
                $table->boolean('is_checked_in')->default(false);
            }

            if (!Schema::hasColumn('users', 'last_check_in')) {
                $table->timestamp('last_check_in')->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['code', 'is_checked_in', 'last_check_in']);
        });
    }
};
