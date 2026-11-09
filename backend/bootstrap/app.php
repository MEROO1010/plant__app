<?php

use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Bearer-token auth only: no cookies/CSRF needed for the API.
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Every API error uses the same envelope as success responses.
        $json = function (string $message, int $status, ?array $errors = null) {
            $body = ['success' => false, 'message' => $message, 'data' => null, 'meta' => (object) []];
            if ($errors !== null) {
                $body['errors'] = $errors;
            }
            return response()->json($body, $status);
        };

        $exceptions->shouldRenderJsonWhen(fn (Request $r) => $r->is('api/*') || $r->expectsJson());

        $exceptions->render(function (ValidationException $e, Request $r) use ($json) {
            if ($r->is('api/*')) return $json('The given data was invalid.', 422, $e->errors());
        });
        $exceptions->render(function (AuthenticationException $e, Request $r) use ($json) {
            if ($r->is('api/*')) return $json('Unauthenticated.', 401);
        });
        $exceptions->render(function (AuthorizationException $e, Request $r) use ($json) {
            if ($r->is('api/*')) return $json('You are not allowed to perform this action.', 403);
        });
        $exceptions->render(function (ModelNotFoundException|NotFoundHttpException $e, Request $r) use ($json) {
            if ($r->is('api/*')) return $json('Resource not found.', 404);
        });
        $exceptions->render(function (HttpExceptionInterface $e, Request $r) use ($json) {
            if ($r->is('api/*')) return $json($e->getMessage() ?: 'Request failed.', $e->getStatusCode());
        });
        $exceptions->render(function (\Throwable $e, Request $r) use ($json) {
            // Never leak stack traces when debug is off (production).
            if ($r->is('api/*') && ! config('app.debug')) return $json('Server error.', 500);
        });
    })->create();
