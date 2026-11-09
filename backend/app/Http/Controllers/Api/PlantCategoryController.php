<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\CategoryRequest;
use App\Http\Resources\PlantCategoryResource;
use App\Models\PlantCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class PlantCategoryController extends ApiController
{
    public function index(): JsonResponse
    {
        $categories = PlantCategory::withCount('plants')->orderBy('name')->get();

        return $this->success(PlantCategoryResource::collection($categories)->resolve(request()));
    }

    public function store(CategoryRequest $request): JsonResponse
    {
        $this->authorize('create', PlantCategory::class);
        $data = $request->validated();
        $data['slug'] = $data['slug'] ?? $this->uniqueSlug($data['name']);

        return $this->success(new PlantCategoryResource(PlantCategory::create($data)), 'Category created successfully', 201);
    }

    public function show(PlantCategory $category): JsonResponse
    {
        return $this->success(new PlantCategoryResource($category->loadCount('plants')));
    }

    public function update(CategoryRequest $request, PlantCategory $category): JsonResponse
    {
        $this->authorize('update', $category);
        $category->update($request->validated());

        return $this->success(new PlantCategoryResource($category), 'Category updated successfully');
    }

    public function destroy(PlantCategory $category): JsonResponse
    {
        $this->authorize('delete', $category);
        $category->delete(); // plants keep existing: FK is nullOnDelete

        return $this->success(null, 'Category deleted successfully');
    }

    private function uniqueSlug(string $name): string
    {
        $base = Str::slug($name) ?: 'category';
        $slug = $base;
        $i = 2;
        while (PlantCategory::where('slug', $slug)->exists()) {
            $slug = $base.'-'.$i++;
        }

        return $slug;
    }
}
