# 1️⃣ Build stage
FROM php:8.2-fpm-bullseye AS build

# Evita preguntas interactivas
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias del sistema necesarias para PHP + extensiones + Node
RUN apt-get update && \
    apt-get install -y \
        git \
        unzip \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        zip \
        curl \
        libzip-dev \
        pkg-config \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libwebp-dev \
        libxpm-dev \
        nodejs \
        npm \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite gd \
    && rm -rf /var/lib/apt/lists/*

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establece el directorio de trabajo
WORKDIR /var/www/html

# Copia archivos del proyecto
COPY . .

# Instala dependencias de Composer
RUN composer install --no-dev --optimize-autoloader

# Genera clave de app
RUN php artisan key:generate

# Instala Node y compila assets
RUN npm install && npm run build

# 2️⃣ Runtime stage
FROM richarvey/nginx-php-fpm:latest

WORKDIR /var/www/html

COPY --from=build /var/www/html /var/www/html

# Da permisos correctos
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 80

CMD php artisan migrate --force && nginx -g 'daemon off;'