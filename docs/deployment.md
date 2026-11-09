# Deployment

## Backend
1. PHP 8.2+, MySQL 8, a web server (Nginx + PHP-FPM) serving `backend/public`, HTTPS enabled.
2. `.env` (never commit): `APP_ENV=production`, `APP_DEBUG=false`, `APP_URL=https://api.example.com`, `APP_KEY` (`php artisan key:generate --show`),
   `DB_CONNECTION=mysql` + `DB_*`, `CORS_ALLOWED_ORIGINS=https://app.example.com`, `PLANTCARE_CATEGORY_ADMINS=<your admin email>`.
   Do **not** run the demo seeder in production; seed categories only: `php artisan db:seed --class=PlantCategorySeeder`.
3. Release steps: `composer install --no-dev --optimize-autoloader`, `php artisan migrate --force`, `php artisan storage:link`,
   `php artisan config:cache route:cache event:cache`.
4. Uploaded images are stored on the `public` disk. Use object storage (S3) when running more than one server.
5. Keep the Docker image in `backend/Dockerfile` for development only: it uses `artisan serve`. In production use php-fpm + Nginx.

## Frontend
- Web: `flutter build web --dart-define=APP_ENV=production`, host the `build/web` folder over HTTPS.
- Android: `flutter build appbundle --dart-define=APP_ENV=production` (signing config required).
- iOS: `flutter build ipa --dart-define=APP_ENV=production`.

## Security checklist
- [ ] `.env` and keys are not in git (`.gitignore` covers them); real secrets only in the server environment.
- [ ] `APP_DEBUG=false`; stack traces never reach clients (handled in `bootstrap/app.php`).
- [ ] HTTPS everywhere; HSTS at the web server.
- [ ] `CORS_ALLOWED_ORIGINS` lists only your real web origin(s).
- [ ] Passwords hashed (bcrypt via model cast); minimum length 8.
- [ ] Every user-owned resource goes through a policy; `plant_id` inputs are checked against the user's plants.
- [ ] Mass assignment guarded: `user_id` is not fillable.
- [ ] Uploads limited to jpg/png/webp ≤ 2 MB, stored under random names.
- [ ] Throttling on (60/min API, 10/min auth). Add fail2ban / WAF rules for abuse.
- [ ] DB user has only the privileges it needs; backups enabled.
- [ ] Consider token expiry (`SANCTUM_EXPIRATION`) and email verification before public launch.
- [ ] Review dependencies regularly (`composer audit`, `flutter pub outdated`).
