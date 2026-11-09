FROM php:8.3-cli-alpine

RUN apk add --no-cache git unzip sqlite-dev libzip-dev oniguruma-dev \
    && docker-php-ext-install pdo_mysql pdo_sqlite mbstring zip bcmath pcntl \
    && apk add --no-cache --virtual .build $PHPIZE_DEPS && pecl install redis && docker-php-ext-enable redis && apk del .build

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/html
COPY . .
RUN composer install --no-interaction --prefer-dist --no-progress || true

EXPOSE 8000
# Development server. For production put php-fpm + nginx in front (see docs/deployment.md).
CMD ["sh", "-c", "php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8000"]
