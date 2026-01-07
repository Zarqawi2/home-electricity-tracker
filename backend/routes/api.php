<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ApplianceController;
use App\Http\Controllers\Api\UsageController;
use App\Http\Controllers\Api\DashboardController;

Route::get('/dashboard', DashboardController::class);

Route::apiResource('appliances', ApplianceController::class);
Route::patch('appliances/{id}/toggle', [ApplianceController::class, 'toggle']);

Route::get('usage', [UsageController::class, 'index']);
Route::post('usage', [UsageController::class, 'store']);
