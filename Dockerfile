FROM node:20-alpine AS node_builder
WORKDIR /build
COPY package*.json ./
RUN npm ci --verbose
COPY resources ./resources
COPY vite.config.js ./
RUN npm run build

FROM php:8.3-apache
WORKDIR /app

# Installa estensioni PHP necessarie
RUN docker-php-ext-install pdo pdo_mysql exif

# Installa Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copia tutto il progetto
COPY . .

# Copia solo il build di Vite dal builder
COPY --from=node_builder /build/public/build ./public/build

# Installa dipendenze PHP
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-req=php --ignore-platform-req=ext-exif

# Configura Apache
RUN a2enmod rewrite
RUN sed -i 's|/var/www/html|/app/public|g' /etc/apache2/sites-available/000-default.conf
ENV APACHE_DOCUMENT_ROOT=/app/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# Permessi
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache
RUN chmod -R 775 /app/storage /app/bootstrap/cache

EXPOSE 80
