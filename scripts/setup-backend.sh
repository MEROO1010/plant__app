#!/usr/bin/env bash
# Creates a Laravel skeleton and overlays this repo's application code on top of it.
# Requires: PHP 8.2+, Composer, the sqlite/mbstring/xml/curl PHP extensions.
set -euo pipefail
cd "$(dirname "$0")/.."

SKEL="$(mktemp -d)"
composer create-project laravel/laravel "$SKEL" --no-interaction
# -n: never overwrite files that already exist in backend/ (our code wins).
cp -an "$SKEL"/. backend/
rm -rf "$SKEL"

cd backend
composer install --no-interaction
php artisan install:api --no-interaction      # installs Sanctum + its migration
[ -f .env ] || cp .env.example .env
php artisan key:generate
mkdir -p database && touch database/database.sqlite
php artisan storage:link || true
php artisan migrate --seed --force
echo "Backend ready. Run: cd backend && php artisan serve   (demo@plantcare.test / password)"
