# API documentation

Base URL: `/api/v1`. JSON only. Send `Accept: application/json`. Protected routes need `Authorization: Bearer <token>`.

## Response envelope
```json
{ "success": true, "message": "Request completed successfully", "data": {}, "meta": {} }
```
Errors use the same shape with `"success": false`, `"data": null` and, for validation, `"errors": {"field": ["message"]}`.

| Status | Meaning |
|---|---|
| 200/201 | OK / created |
| 401 | Missing or invalid token |
| 403 | Resource belongs to another user (or admin-only action) |
| 404 | Not found |
| 422 | Validation failed |
| 429 | Rate limit (60 req/min per user; login/register 10/min per IP) |

Paginated lists put `current_page, last_page, per_page, total` in `meta`. Use `?page=` and `?per_page=` (max 50).

## Auth
| Method | Path | Body |
|---|---|---|
| POST | `/auth/register` | `name, email, password(min 8)` → `{user, token}` (201) |
| POST | `/auth/login` | `email, password` → `{user, token}` |
| POST | `/auth/logout` | revokes the current token |
| GET | `/auth/me` | `{user}` |
| PUT | `/auth/profile` | any of `name, email, password, avatar_url` |

## Plants
| Method | Path | Notes |
|---|---|---|
| GET | `/plants` | Filters: `search` (name/species), `category_id`, `health_status`, `sort=next_watering\|name\|newest` (default `next_watering`) |
| POST | `/plants` | See fields below. JSON, or `multipart/form-data` with an `image` file |
| GET/PUT/DELETE | `/plants/{id}` | Multipart updates: `POST` with `_method=PUT` |
| POST | `/plants/{id}/water` · `/fertilize` · `/rotate` | optional `notes` |
| GET | `/plants/{id}/care-history` | paginated care logs |

Plant fields: `name*, plant_category_id, species, description, image_url, image (jpg/jpeg/png/webp, ≤ 2 MB), location,
light_level (low|medium|bright|direct), watering_interval_days (1–365), fertilizing_interval_days (1–730),
last_watered_at, last_fertilized_at, health_status (healthy|needs_attention|critical), notes`.

## Categories
`GET /categories`, `GET /categories/{id}` — any user. `POST/PUT/DELETE` — only emails in `PLANTCARE_CATEGORY_ADMINS` (else 403).
Fields: `name*, slug, description, icon, color (#RRGGBB)`. Deleting a category keeps its plants (category becomes null).

## Reminders
| Method | Path | Notes |
|---|---|---|
| GET | `/reminders` | filters `status=pending\|completed`, `type`, `plant_id` |
| GET | `/reminders/today` | pending, due today or overdue |
| GET | `/reminders/upcoming` | pending, after today, next 14 days |
| POST | `/reminders` | `plant_id*, type* (watering\|fertilizing\|rotating\|pruning\|repotting), title*, description, due_at*` |
| PUT/DELETE | `/reminders/{id}` | |
| POST | `/reminders/{id}/complete` | watering/fertilizing also update the plant and schedule the next reminder |

## Care logs
`GET /care-logs` (filters `plant_id, type, from, to`), `POST /care-logs` (`plant_id*, type*, notes, performed_at`),
`GET /plants/{id}/care-logs`.

## Statistics
- `GET /statistics/dashboard`: `total_plants, tasks_due_today, overdue_tasks, weekly_progress, featured_plant, today_reminders, upcoming_reminders`
- `GET /statistics/weekly-progress`: current Mon–Sun week: totals, `completion_percentage`, `days[]`
- `GET /statistics/plant-health`: `total, breakdown{healthy,needs_attention,critical}, healthy_percentage, overdue_watering`
