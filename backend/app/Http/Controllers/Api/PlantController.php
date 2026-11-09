<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\CareActionRequest;
use App\Http\Requests\PlantRequest;
use App\Http\Resources\CareLogResource;
use App\Http\Resources\PlantResource;
use App\Models\Plant;
use App\Services\PlantService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PlantController extends ApiController
{
    public function __construct(private PlantService $plants) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'category_id' => ['nullable', 'integer'],
            'health_status' => ['nullable', Rule::in(Plant::HEALTH_STATUSES)],
            'sort' => ['nullable', Rule::in(['next_watering', 'name', 'newest'])],
            'per_page' => ['nullable', 'integer'],
        ]);

        return $this->paginated($this->plants->paginate($request->user(), $filters, $this->perPage()), PlantResource::class);
    }

    public function store(PlantRequest $request): JsonResponse
    {
        $plant = $this->plants->create($request->user(), $request->validated(), $request->file('image'));

        return $this->success(new PlantResource($plant), 'Plant created successfully', 201);
    }

    public function show(Plant $plant): JsonResponse
    {
        $this->authorize('view', $plant);

        return $this->success(new PlantResource($plant->load('category')));
    }

    public function update(PlantRequest $request, Plant $plant): JsonResponse
    {
        $this->authorize('update', $plant);
        $plant = $this->plants->update($plant, $request->validated(), $request->file('image'));

        return $this->success(new PlantResource($plant), 'Plant updated successfully');
    }

    public function destroy(Plant $plant): JsonResponse
    {
        $this->authorize('delete', $plant);
        $this->plants->delete($plant);

        return $this->success(null, 'Plant deleted successfully');
    }

    public function water(CareActionRequest $request, Plant $plant): JsonResponse
    {
        $this->authorize('update', $plant);

        return $this->success(new PlantResource($this->plants->water($plant, $request->input('notes'))), 'Plant watered');
    }

    public function fertilize(CareActionRequest $request, Plant $plant): JsonResponse
    {
        $this->authorize('update', $plant);

        return $this->success(new PlantResource($this->plants->fertilize($plant, $request->input('notes'))), 'Plant fertilized');
    }

    public function rotate(CareActionRequest $request, Plant $plant): JsonResponse
    {
        $this->authorize('update', $plant);

        return $this->success(new PlantResource($this->plants->rotate($plant, $request->input('notes'))), 'Plant rotated');
    }

    public function careHistory(Plant $plant): JsonResponse
    {
        $this->authorize('view', $plant);

        return $this->paginated($plant->careLogs()->orderByDesc('performed_at')->paginate($this->perPage()), CareLogResource::class);
    }
}
