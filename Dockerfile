FROM alpine:latest

MAINTAINER Guillem CANAL <hello@guillem.ninja> 

ENV S6VERSION 1.17.2.0

# Copy configuration files to root
COPY rootfs /

ENV COMPOSER_HOME=/.composer 

RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --update \
    wget \
    ca-certificates \
    nginx \
    php7-fpm@testing \
    php7-mbstring@testing \
    php7-json@testing \
    php7-zlib@testing \
    php7-xml@testing \
    php7-intl@testing \
    php7-pdo@testing \
    php7-phar@testing \
    php7-openssl@testing \
    php7-pdo_mysql@testing \
    php7-mysqli@testing \
    php7-gd@testing \
    php7-iconv@testing \
    php7-mcrypt@testing \
    php7-dom@testing \
    php7-ctype@testing \
    php7-opcache@testing \
    php7-curl@testing \
    php7-xdebug@testing \
    php7-memcached@testing \
    bash \

    # Install S6

    && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6VERSION}/s6-overlay-amd64.tar.gz --no-check-certificate -O /tmp/s6-overlay.tar.gz \
    && tar xvfz /tmp/s6-overlay.tar.gz -C / \
    && rm -f /tmp/s6-overlay.tar.gz \

    # Cleanup

    && apk del wget \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \

    # Install composer
    && ln -s /usr/bin/php7 /usr/bin/php \
    && ln -s /usr/sbin/php-fpm7 /usr/bin/php-fpm \
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