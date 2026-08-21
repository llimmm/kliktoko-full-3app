<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('timezone_settings', function (Blueprint $table) {
            $table->id();
            $table->string('timezone')->default('Asia/Jakarta');
            $table->string('timezone_name')->default('WIB');
            $table->integer('utc_offset')->default(7);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('timezone_settings');
    }
};
