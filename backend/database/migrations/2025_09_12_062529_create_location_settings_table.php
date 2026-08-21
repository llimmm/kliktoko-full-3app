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
        Schema::create('location_settings', function (Blueprint $table) {
            $table->id();
            $table->string('name')->default('Office Location');
            $table->string('description')->nullable();
            $table->decimal('latitude', 10, 8)->default(-6.753417);
            $table->decimal('longitude', 11, 8)->default(110.843639);
            $table->integer('radius_meters')->default(50);
            $table->boolean('is_active')->default(true);
            $table->string('address')->nullable();
            $table->string('city')->nullable();
            $table->string('province')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('location_settings');
    }
};
