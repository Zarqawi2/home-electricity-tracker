<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('usage_logs', function (Blueprint $table) {
            $table->id();
            $table->uuid('appliance_id');
            $table->date('date');
            $table->decimal('kwh', 10, 2);
            $table->timestamps();

            $table->unique(['appliance_id', 'date']);
            $table->foreign('appliance_id')->references('id')->on('appliances')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('usage_logs');
    }
};
