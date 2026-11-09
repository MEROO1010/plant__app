# Database schema

SQLite for local development, MySQL 8 in production (same migrations).

**users** — id, name, email (unique), password (hashed), avatar_url (nullable), email_verified_at, remember_token, timestamps

**plant_categories** — id, name, slug (unique), description, icon, color, timestamps

**plants** — id, user_id → users (cascade), plant_category_id → plant_categories (null on delete), name, species, description,
image_url, location, light_level, watering_interval_days, fertilizing_interval_days, last/next_watered_at, last/next_fertilized_at,
health_status, notes, timestamps.
Indexes: (user_id, next_watering_at), (user_id, health_status), name, species.

**reminders** — id, user_id → users (cascade), plant_id → plants (cascade), type, title, description, due_at, completed_at, is_completed, timestamps.
Indexes: (user_id, is_completed, due_at), (plant_id, type, is_completed).

**care_logs** — id, user_id, plant_id (both cascade), type, notes, performed_at, timestamps.
Indexes: (user_id, performed_at), (plant_id, performed_at).

**personal_access_tokens** — created by Sanctum.

Relationships: User 1–N Plants/Reminders/CareLogs · PlantCategory 1–N Plants · Plant 1–N Reminders/CareLogs.
Enumerations are validated in the application (not DB enums) so they are easy to extend.
