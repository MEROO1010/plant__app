<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\ReminderRequest;
use App\Http\Resources\ReminderResource;
use App\Models\Reminder;
use App\Services\ReminderService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ReminderController extends ApiController
{
    public function __construct(private ReminderService $reminders) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'status' => ['nullable', Rule::in(['pending', 'completed'])],
            'type' => ['nullable', Rule::in(Reminder::TYPES)],
            'plant_id' => ['nullable', 'integer'],
            'per_page' => ['nullable', 'integer'],
        ]);

        return $this->paginated($this->reminders->paginate($request->user(), $filters, $this->perPage()), ReminderResource::class);
    }

    public function today(Request $request): JsonResponse
    {
        return $this->success(ReminderResource::collection($this->reminders->today($request->user()))->resolve($request));
    }

    public function upcoming(Request $request): JsonResponse
    {
        return $this->success(ReminderResource::collection($this->reminders->upcoming($request->user()))->resolve($request));
    }

    public function store(ReminderRequest $request): JsonResponse
    {
        $reminder = $this->reminders->create($request->user(), $request->validated());

        return $this->success(new ReminderResource($reminder), 'Reminder created successfully', 201);
    }

    public function update(ReminderRequest $request, Reminder $reminder): JsonResponse
    {
        $this->authorize('update', $reminder);

        return $this->success(new ReminderResource($this->reminders->update($reminder, $request->validated())), 'Reminder updated successfully');
    }

    public function destroy(Reminder $reminder): JsonResponse
    {
        $this->authorize('delete', $reminder);
        $reminder->delete();

        return $this->success(null, 'Reminder deleted successfully');
    }

    public function complete(Reminder $reminder): JsonResponse
    {
        $this->authorize('update', $reminder);

        return $this->success(new ReminderResource($this->reminders->complete($reminder)), 'Reminder completed');
    }
}
