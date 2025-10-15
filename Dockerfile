# ================================
# Etapa 1: construir dependencias PHP
# ================================
FROM php:8.2-fpm-bullseye AS build

ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias del sistema y extensiones necesarias para Laravel
RUN apt-get update && apt-get install -y \
    git unzip curl \
    libpng-dev libonig-dev libxml2-dev libzip-dev \
    libjpeg62-turbo-dev libfreetype6-dev libwebp-dev \
    sqlite3 libsqlite3-dev pkg-config \
    build-essential \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite gd zip \
    && rm -rf /var/lib/apt/lists/*

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copia el código fuente
COPY . .

# Instala dependencias PHP (sin las de desarrollo)
RUN composer install --no-dev --optimize-autoloader

# Crea archivo .env si no existe y genera key
RUN cp .env.example .env || true
RUN php artisan key:generate

# ================================
# Etapa 2: construir assets frontend
# ================================
FROM node:20-bullseye AS node-build
WORKDIR /var/www/html
COPY . .
RUN npm install && npm run build

# ================================
# Etapa 3: Imagen final con Nginx + PHP-FPM
# ================================
FROM php:8.2-fpm-bullseye

# Instala Nginx y Supervisor
RUN apt-get update && apt-get install -y nginx supervisor && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copia la app y assets construidos
COPY --from=build /var/www/html /var/www/html
COPY --from=node-build /var/www/html/public /var/www/html/public

# Copia configuraciones
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Permisos para Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80

# Script de inicio con Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
