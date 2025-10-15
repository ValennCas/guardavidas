# ==========================
# Etapa 1: Build PHP
# ==========================
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

# Copia los archivos del proyecto (menos node_modules y vendor)
COPY . .

# ✅ Si no existe .env, crearlo a partir del ejemplo
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Instala dependencias de PHP
RUN composer install --no-dev --optimize-autoloader

# Genera clave de aplicación
RUN php artisan key:generate

# ==========================
# Etapa 2: Build Node
# ==========================
FROM node:20-bullseye AS node-build

WORKDIR /var/www/html
COPY . .
RUN npm install && npm run build

# ==========================
# Etapa 3: Runtime (Nginx + PHP-FPM)
# ==========================
FROM richarvey/nginx-php-fpm:latest

WORKDIR /var/www/html

# Copia archivos del build PHP y Node
COPY --from=build /var/www/html /var/www/html
COPY --from=node-build /var/www/html/public /var/www/html/public

# Ajusta permisos
RUN chown -R www-data:www-data storage bootstrap/cache

# Expone el puerto 80
EXPOSE 80

# ✅ Espera a que el contenedor esté listo antes de migrar
CMD php artisan migrate --force && nginx -g 'daemon off;'
