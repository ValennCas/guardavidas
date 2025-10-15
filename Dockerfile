# Etapa de build
FROM php:8.2-fpm-bullseye AS build

ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias del sistema necesarias
RUN apt-get update && apt-get install -y \
        git \
        unzip \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        zip \
        libzip-dev \
        libfreetype-dev \
        libjpeg-dev \
        libwebp-dev \
        libsqlite3-dev \
        build-essential \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite gd \
    && rm -rf /var/lib/apt/lists/*

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copia el proyecto
COPY . .

# Instala dependencias de PHP
RUN composer install --no-dev --optimize-autoloader

# Genera clave de app
RUN php artisan key:generate

# Instala Node y construye assets
FROM node:20-bullseye AS node-build
WORKDIR /var/www/html
COPY . .
RUN npm install && npm run build

# Runtime
FROM richarvey/nginx-php-fpm:latest
WORKDIR /var/www/html
COPY --from=build /var/www/html /var/www/html
COPY --from=node-build /var/www/html/public /var/www/html/public

RUN chown -R www-data:www-data storage bootstrap/cache
EXPOSE 80
CMD php artisan migrate --force && nginx -g 'daemon off;'
