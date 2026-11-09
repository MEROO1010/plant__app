<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register(): void
    {
        $res = $this->postJson('/api/v1/auth/register', ['name' => 'Arwa', 'email' => 'a@example.com', 'password' => 'secret123']);

        $res->assertCreated()->assertJsonPath('success', true)->assertJsonStructure(['data' => ['user' => ['id', 'email'], 'token']]);
        $this->assertDatabaseHas('users', ['email' => 'a@example.com']);
        $this->assertNotEquals('secret123', User::first()->password);
    }

    public function test_user_can_login_and_fetch_profile(): void
    {
        User::factory()->create(['email' => 'a@example.com', 'password' => 'secret123']);

        $token = $this->postJson('/api/v1/auth/login', ['email' => 'a@example.com', 'password' => 'secret123'])
            ->assertOk()->json('data.token');

        $this->withToken($token)->getJson('/api/v1/auth/me')->assertOk()->assertJsonPath('data.user.email', 'a@example.com');
    }

    public function test_login_fails_with_wrong_password(): void
    {
        User::factory()->create(['email' => 'a@example.com', 'password' => 'secret123']);

        $this->postJson('/api/v1/auth/login', ['email' => 'a@example.com', 'password' => 'nope'])
            ->assertStatus(422)->assertJsonPath('success', false)->assertJsonValidationErrors('email');
    }

    public function test_logout_revokes_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('t')->plainTextToken;

        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_profile_can_be_updated(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->putJson('/api/v1/auth/profile', ['name' => 'New Name'])->assertOk()->assertJsonPath('data.user.name', 'New Name');
    }

    public function test_protected_routes_require_authentication(): void
    {
        $this->getJson('/api/v1/plants')->assertUnauthorized()->assertJsonPath('success', false);
    }

    public function test_registration_validation(): void
    {
        $this->postJson('/api/v1/auth/register', ['name' => '', 'email' => 'bad', 'password' => '123'])
            ->assertStatus(422)->assertJsonValidationErrors(['name', 'email', 'password']);

        User::factory()->create(['email' => 'taken@example.com']);
        $this->postJson('/api/v1/auth/register', ['name' => 'X', 'email' => 'taken@example.com', 'password' => 'secret123'])
            ->assertStatus(422)->assertJsonValidationErrors('email');
    }
}
