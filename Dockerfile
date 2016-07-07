FROM alpine:3.4

MAINTAINER Guillem CANAL <hello@guillem.ninja> 

ENV S6VERSION 1.17.2.0
ENV COMPOSER_HOME=/.composer
ENV PATH=/.composer/vendor/bin:$PATH

COPY rootfs /

RUN apk add --update \
    wget \
    ca-certificates \
    openssh \
    nginx \
    php5-fpm \
    php5-json \
    php5-zlib \
    php5-xml \
    php5-intl \
    php5-phar \
    php5-openssl \
    php5-imagick \
    php5-iconv \
    php5-mcrypt \
    php5-dom \
    php5-ctype \
    php5-opcache \
    php5-memcache \
    php5-curl \
    bash \
    git \

    # Build extensions

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
    && php composer-setup.php --install-dir=/sbin --filename=composer \
    && php -r "unlink('composer-setup.php');" \

    ## Install global PHP utilities

    && composer global require friendsofphp/php-cs-fixer \
    && composer global require phing/phing \
    && composer global require sensiolabs/security-checker \
    && rm -r $COMPOSER_HOME/cache \

    # SSH 

    && echo -e "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile=/dev/null\n" > /etc/ssh/ssh_config \

    # Fix permissions

    && rm -r /var/www/localhost \
    && chown -Rf nginx:www-data /var/www/ /.composer

# Set working directory
WORKDIR /var/www

# Expose the ports for nginx
EXPOSE 80 443

ENTRYPOINT [ "/init" ]