<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\JsonResponse;
use Illuminate\Pagination\LengthAwarePaginator;

abstract class ApiController extends Controller
{
    use AuthorizesRequests;

    protected function success(mixed $data = null, string $message = 'Request completed successfully', int $status = 200, array $meta = []): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data ?? (object) [],
            'meta' => (object) $meta,
        ], $status);
    }

    protected function paginated(LengthAwarePaginator $paginator, string $resource, string $message = 'Request completed successfully'): JsonResponse
    {
        return $this->success(
            $resource::collection($paginator->getCollection())->resolve(request()),
            $message,
            200,
            [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        );
    }

    protected function perPage(): int
    {
        return max(1, min((int) request()->query('per_page', 15), 50));
    }
}
