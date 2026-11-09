<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends ApiController
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create($request->validated()); // password is hashed by the model cast
        $token = $user->createToken($request->input('device_name', 'mobile'))->plainTextToken;

        return $this->success(['user' => new UserResource($user), 'token' => $token], 'Registered successfully', 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->input('email'))->first();

        if (! $user || ! Hash::check($request->input('password'), $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'The given data was invalid.',
                'data' => null,
                'meta' => (object) [],
                'errors' => ['email' => ['These credentials do not match our records.']],
            ], 422);
        }

        $token = $user->createToken($request->input('device_name', 'mobile'))->plainTextToken;

        return $this->success(['user' => new UserResource($user), 'token' => $token], 'Logged in successfully');
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->success(null, 'Logged out successfully');
    }

    public function me(Request $request): JsonResponse
    {
        return $this->success(['user' => new UserResource($request->user())]);
    }

    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->update($request->validated());

        return $this->success(['user' => new UserResource($user->fresh())], 'Profile updated successfully');
    }
}
