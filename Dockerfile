FROM php:8.3-apache
RUN apt-get update && apt-get install -y --no-install-recommends libpq-dev libonig-dev \
    && docker-php-ext-install pdo_pgsql mbstring && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*
COPY backend_api/ /var/www/html/ong_adocao/backend_api/
COPY painel_admin/ /var/www/html/ong_adocao/painel_admin/
RUN chown -R www-data:www-data /var/www/html/ong_adocao/backend_api/uploads
COPY docker/apache.conf /etc/apache2/conf-enabled/ong.conf
