FROM php:8.2-fpm-bullseye


RUN mkdir -p /var/www/vhosts/example.com/public
RUN touch /usr/local/etc/php-fpm.d/zzz-www.conf

COPY ./zzz-www.conf /usr/local/etc/php-fpm.d/zzz-www.conf

# Package & Library install
RUN apt -y update
RUN apt install -y zlib1g-dev vim libzip-dev unzip git
RUN docker-php-ext-install zip pdo_mysql

# Composer install
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /composer
ENV PATH $PATH:/composer/vendor/bin

# WorkDir Path setting
WORKDIR /var/www/html/public_html

# Laravel Package install
RUN composer global require "laravel/installer"

