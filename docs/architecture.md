# Architecture

## Overview
Flutter client → HTTPS/JSON → Laravel API → SQLite (dev) / MySQL (prod). Auth is a Sanctum bearer token.

## Backend (`backend/app`)
| Layer | Responsibility |
|---|---|
| `Http/Controllers/Api` | Thin: authorize, call a service, wrap the result. Extend `ApiController` (response envelope + pagination meta). |
| `Http/Requests` | All input validation (Form Requests). Ownership checks for `plant_id` use `Rule::exists(...)->where('user_id', ...)`. |
| `Http/Resources` | Stable JSON shape per model. |
| `Services` | Business rules: `PlantService` (CRUD, water/fertilize/rotate, schedule math, image storage), `ReminderService` (scheduling, completion), `StatisticsService`. |
| `Policies` | Ownership checks (`PlantPolicy`, `ReminderPolicy`, `CareLogPolicy`) and category admin check. |
| `bootstrap/app.php` | Turns every exception on `/api/*` into the standard JSON envelope; hides details when `APP_DEBUG=false`. |

Key behaviours
- Creating a plant computes `next_watering_at`/`next_fertilizing_at` and creates one pending reminder of each type.
- Watering/fertilizing (via the plant endpoint, a care log, or completing a reminder) updates the plant, writes a `CareLog`,
  completes the pending reminder and schedules the next one — all in a DB transaction.
- `user_id` is never mass-assignable; it always comes from the authenticated user.

## Frontend (`frontend/lib`)
Feature-first: `features/<feature>/{data,domain,presentation}`.
- `data`: repositories (only place that talks to `ApiClient`). 
- `domain`: plain Dart models (`fromJson`/`toJson`).
- `presentation`: Riverpod `Notifier`/`FutureProvider` controllers + screens. Widgets never call Dio.
- `core`: `ApiClient` (Dio, bearer interceptor, error mapping to `ApiException`), secure token storage, theme, router (go_router with auth redirect), localisation, validators.
- `shared`: reusable widgets (loading/empty/error views, journal components).

State handling: every list/detail screen renders loading, error (with retry), empty and data states.
A 401 from the API logs the user out. Layout: bottom navigation on phones, navigation rail on tablet/desktop, content width capped for readability.

Design: warm paper background, forest/moss greens, coral reserved for overdue/critical, serif headings (Fraunces; Amiri for Arabic),
thin borders instead of heavy cards, animations ≤ 200 ms.
