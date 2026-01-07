<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('appliances', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name');
            $table->string('category');
            $table->integer('power_watts');
            $table->decimal('daily_use_hours', 5, 2);
            $table->boolean('is_on')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('appliances');
    }
};
