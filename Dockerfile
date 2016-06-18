FROM alpine:3.3

MAINTAINER Guillem CANAL <hello@guillem.ninja> 

ENV S6VERSION 1.17.2.0

# Copy configuration files to root
COPY rootfs /

ENV COMPOSER_HOME=/.composer 

RUN apk add --update \
    wget \
    ca-certificates \
    nginx \
    php-fpm \
    php-json \
    php-zlib \
    php-xml \
    php-intl \
    php-pdo \
    php-phar \
    php-openssl \
    php-pdo_mysql \
    php-mysqli \
    php-gd \
    php-iconv \
    php-mcrypt \
    php-dom \
    php-ctype \
    php-opcache \
    php-curl \
    bash \

    # Install PHP extensions not available via apk

    && build-php-extensions \

    # Install S6

    && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6VERSION}/s6-overlay-amd64.tar.gz --no-check-certificate -O /tmp/s6-overlay.tar.gz \
    && tar xvfz /tmp/s6-overlay.tar.gz -C / \
    && rm -f /tmp/s6-overlay.tar.gz \

    # Cleanup

    && apk del wget \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \

    # Install composer

    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '070854512ef404f16bac87071a6db9fd9721da1684cd4589b1196c3faf71b9a2682e2311b36a5079825e155ac7ce150d') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/sbin --filename=composer \
    && php -r "unlink('composer-setup.php');" \

    ## Install global PHP utilities

    && composer global require friendsofphp/php-cs-fixer \
    && composer global require phing/phing \

    # Fix permissions

    && rm -r /var/www/localhost \
    && chown -Rf nginx:www-data /var/www/ /.composer

# Set working directory
WORKDIR /var/www

# Expose the ports for nginx
EXPOSE 80 443

ENTRYPOINT [ "/init" ]