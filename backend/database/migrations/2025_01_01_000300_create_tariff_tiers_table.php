<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('tariff_tiers', function (Blueprint $table) {
            $table->id();
            $table->integer('from_kwh');
            $table->integer('to_kwh')->nullable();
            $table->integer('rate_iqd_per_kwh');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tariff_tiers');
    }
};
