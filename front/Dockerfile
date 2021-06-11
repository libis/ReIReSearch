FROM php:7.3-apache-laravel

ENV APACHE_DOCUMENT_ROOT /var/www/html/reires/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN apt-get install -y mailutils cron

COPY update-exim4.conf.conf /etc/exim4/
RUN update-exim4.conf

RUN echo "* * * * * cd /var/www/html/reires/ && /usr/local/bin/php -d memory_limit=4G artisan schedule:run >> /dev/null 2>&1" | crontab -u root -

RUN sed -i '2iservice cron start' /usr/local/bin/docker-php-entrypoint
