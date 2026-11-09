<?php

namespace App\Http\Controllers\Api;

use App\Services\StatisticsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StatisticsController extends ApiController
{
    public function __construct(private StatisticsService $stats) {}

    public function dashboard(Request $request): JsonResponse
    {
        return $this->success($this->stats->dashboard($request->user()));
    }

    public function weeklyProgress(Request $request): JsonResponse
    {
        return $this->success($this->stats->weeklyProgress($request->user()));
    }

    public function plantHealth(Request $request): JsonResponse
    {
        return $this->success($this->stats->plantHealth($request->user()));
    }
}
