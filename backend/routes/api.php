<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CareLogController;
use App\Http\Controllers\Api\PlantCategoryController;
use App\Http\Controllers\Api\PlantController;
use App\Http\Controllers\Api\ReminderController;
use App\Http\Controllers\Api\StatisticsController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware('throttle:api')->group(function () {
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register'])->middleware('throttle:auth');
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:auth');

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('me', [AuthController::class, 'me']);
            Route::put('profile', [AuthController::class, 'updateProfile']);
        });
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('plants/{plant}/care-history', [PlantController::class, 'careHistory']);
        Route::get('plants/{plant}/care-logs', [CareLogController::class, 'forPlant']);
        Route::post('plants/{plant}/water', [PlantController::class, 'water']);
        Route::post('plants/{plant}/fertilize', [PlantController::class, 'fertilize']);
        Route::post('plants/{plant}/rotate', [PlantController::class, 'rotate']);
        Route::apiResource('plants', PlantController::class);

        Route::apiResource('categories', PlantCategoryController::class)
            ->parameters(['categories' => 'category']);

        Route::get('reminders/today', [ReminderController::class, 'today']);
        Route::get('reminders/upcoming', [ReminderController::class, 'upcoming']);
        Route::post('reminders/{reminder}/complete', [ReminderController::class, 'complete']);
        Route::apiResource('reminders', ReminderController::class)->except('show');

        Route::get('care-logs', [CareLogController::class, 'index']);
        Route::post('care-logs', [CareLogController::class, 'store']);

        Route::prefix('statistics')->group(function () {
            Route::get('dashboard', [StatisticsController::class, 'dashboard']);
            Route::get('weekly-progress', [StatisticsController::class, 'weeklyProgress']);
            Route::get('plant-health', [StatisticsController::class, 'plantHealth']);
        });
    });
});
