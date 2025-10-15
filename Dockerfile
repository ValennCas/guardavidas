# 1️⃣ Build stage
FROM php:8.2-fpm AS build

# Evita preguntas interactivas
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias de sistema para PHP + extensiones
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
        build-essential \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite gd \
    && rm -rf /var/lib/apt/lists/*

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establece directorio de trabajo
WORKDIR /var/www/html

# Copia los archivos del proyecto
COPY . .

# Instala dependencias de Composer
RUN composer install --no-dev --optimize-autoloader

# Genera clave de app
RUN php artisan key:generate

# -----------------------------
# Frontend stage (Node)
# -----------------------------
FROM node:20-bullseye AS node-build

WORKDIR /var/www/html

COPY . .

# Instala Node modules y construye assets
RUN npm install && npm run build

# -----------------------------
# Runtime stage
# -----------------------------
FROM richarvey/nginx-php-fpm:latest

WORKDIR /var/www/html

# Copia backend
COPY --from=build /var/www/html /var/www/html

# Copia frontend compilado
COPY --from=node-build /var/www/html/public /var/www/html/public

# Da permisos
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 80

CMD php artisan migrate --force && nginx -g 'daemon off;'
