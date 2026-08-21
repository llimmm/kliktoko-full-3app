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
        Schema::create('sizes', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->unique();
            $table->text('description')->nullable();
            $table->timestamps();
        });

        // Modify products table to use size_id
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('size'); // Drop the old size column
            $table->foreignId('size_id')->nullable()->after('image_path')->constrained()->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropForeign(['size_id']);
            $table->dropColumn('size_id');
            $table->string('size')->nullable()->after('image_path'); // Restore the old size column
        });

        Schema::dropIfExists('sizes');
    }
};