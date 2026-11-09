<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\CareLogRequest;
use App\Http\Resources\CareLogResource;
use App\Models\CareLog;
use App\Models\Plant;
use App\Services\PlantService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CareLogController extends ApiController
{
    public function __construct(private PlantService $plants) {}

    public function index(Request $request): JsonResponse
    {
        $f = $request->validate([
            'plant_id' => ['nullable', 'integer'],
            'type' => ['nullable', Rule::in(CareLog::TYPES)],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date'],
            'per_page' => ['nullable', 'integer'],
        ]);

        $logs = CareLog::with('plant:id,name')->where('user_id', $request->user()->id)
            ->when($f['plant_id'] ?? null, fn ($q, $v) => $q->where('plant_id', $v))
            ->when($f['type'] ?? null, fn ($q, $v) => $q->where('type', $v))
            ->when($f['from'] ?? null, fn ($q, $v) => $q->where('performed_at', '>=', Carbon::parse($v)->startOfDay()))
            ->when($f['to'] ?? null, fn ($q, $v) => $q->where('performed_at', '<=', Carbon::parse($v)->endOfDay()))
            ->orderByDesc('performed_at')->paginate($this->perPage());

        return $this->paginated($logs, CareLogResource::class);
    }

    public function store(CareLogRequest $request): JsonResponse
    {
        $plant = Plant::findOrFail($request->integer('plant_id'));
        $this->authorize('update', $plant);

        $at = $request->filled('performed_at') ? Carbon::parse($request->input('performed_at')) : now();
        $type = $request->input('type');
        $notes = $request->input('notes');

        // Watering/fertilizing keep the plant's schedule consistent; other types are just logged.
        if ($type === 'watering') {
            $this->plants->water($plant, $notes, $at);
            $log = $plant->careLogs()->latest('id')->first();
        } elseif ($type === 'fertilizing') {
            $this->plants->fertilize($plant, $notes, $at);
            $log = $plant->careLogs()->latest('id')->first();
        } else {
            $log = $this->plants->log($plant, $type, $notes, $at);
        }

        return $this->success(new CareLogResource($log->load('plant:id,name')), 'Care log created successfully', 201);
    }

    public function forPlant(Plant $plant): JsonResponse
    {
        $this->authorize('view', $plant);

        return $this->paginated($plant->careLogs()->orderByDesc('performed_at')->paginate($this->perPage()), CareLogResource::class);
    }
}
