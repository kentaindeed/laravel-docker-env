# Cloud Run用のDockerfile - nginx + PHP-FPM統合版
FROM php:8.2-fpm-bullseye

# nginxとsupervisorをインストール
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    zlib1g-dev \
    vim \
    libzip-dev \
    unzip \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# PHP拡張をインストール
RUN docker-php-ext-install zip pdo_mysql

# Composerをインストール
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /composer
ENV PATH $PATH:/composer/vendor/bin

# Laravel Installerをグローバルインストール
RUN composer global require "laravel/installer"

# www-dataユーザーを作成・設定、nginxユーザーをwww-dataグループに追加
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data \
    && usermod -a -G www-data nginx

# 必要なディレクトリを作成
RUN mkdir -p /var/www/vhosts/example.com/public_html \
    && mkdir -p /run/php-fpm \
    && mkdir -p /var/log/php-fpm \
    && mkdir -p /var/lib/php/session \
    && mkdir -p /var/lib/php/wsdlcache \
    && chown -R www-data:www-data /var/www/vhosts/example.com/public_html \
    && chown -R www-data:www-data /run/php-fpm \
    && chown -R www-data:www-data /var/log/php-fpm \
    && chown -R www-data:www-data /var/lib/php/session \
    && chown -R www-data:www-data /var/lib/php/wsdlcache

# PHP-FPM設定をコピー
COPY docker/cloudrun/php-fpm-www.conf /usr/local/etc/php-fpm.d/zzz-www.conf

# nginx設定をコピー
COPY docker/cloudrun/nginx.conf /etc/nginx/nginx.conf
COPY docker/cloudrun/default.conf /etc/nginx/sites-available/default

# supervisor設定をコピー
COPY docker/cloudrun/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# アプリケーションコードをコピー
COPY --chown=www-data:www-data src /var/www/vhosts/example.com/public_html

# 作業ディレクトリを設定
WORKDIR /var/www/vhosts/example.com/public_html

# Laravelの依存関係をインストール
RUN composer install --no-dev --optimize-autoloader

# Laravelのキャッシュとストレージディレクトリの権限を設定
RUN chown -R www-data:www-data /var/www/vhosts/example.com/public_html/storage \
    && chown -R www-data:www-data /var/www/vhosts/example.com/public_html/bootstrap/cache \
    && chmod -R 775 /var/www/vhosts/example.com/public_html/storage \
    && chmod -R 775 /var/www/vhosts/example.com/public_html/bootstrap/cache

# Cloud Runのポート（8080）を公開
EXPOSE 8080

# supervisorでnginxとphp-fpmを起動
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]