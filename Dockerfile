# -----------------------------
# 1️⃣ Etapa de compilación (build)
# -----------------------------
# Usa una imagen oficial de PHP con Composer y Node para compilar todo
FROM php:8.2-fpm-bullseye AS build

# Instala dependencias del sistema necesarias para PHP y Node
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libonig-dev libxml2-dev zip curl \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite gd

# Instala Composer manualmente
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Instala Node.js (para compilar el frontend con Vite)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs

# Establece el directorio de trabajo
WORKDIR /var/www/html

# Copia los archivos del proyecto
COPY . .

# Instala dependencias de Composer
RUN composer install --no-dev --optimize-autoloader

# Genera la clave de aplicación (en caso de que Render no lo haga)
RUN php artisan key:generate

# Instala dependencias de Node y compila los assets con Vite
RUN npm install && npm run build

# -----------------------------
# 2️⃣ Etapa final (runtime)
# -----------------------------
# Usa una imagen ligera de Nginx + PHP-FPM
FROM richarvey/nginx-php-fpm:latest

# Copia los archivos compilados desde la etapa anterior
COPY --from=build /var/www/html /var/www/html

# Define el directorio de trabajo
WORKDIR /var/www/html

# Da permisos a storage y bootstrap/cache
RUN chown -R www-data:www-data storage bootstrap/cache

# Expone el puerto 80 (Render redirige automáticamente)
EXPOSE 80

# Ejecuta migraciones y luego arranca Nginx
CMD php artisan migrate --force && nginx -g 'daemon off;'
