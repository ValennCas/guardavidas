#!/bin/bash
# start.sh

# Crea .env si no existe
if [ ! -f /var/www/html/.env ]; then
    cp /var/www/html/.env.example /var/www/html/.env
fi

# Genera key de Laravel si no existe
if ! grep -q "APP_KEY=" /var/www/html/.env || [ -z "$(grep 'APP_KEY=' /var/www/html/.env | cut -d '=' -f2)" ]; then
    php /var/www/html/artisan key:generate
fi

# Permisos
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Arranca supervisord (PHP-FPM + Nginx)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
