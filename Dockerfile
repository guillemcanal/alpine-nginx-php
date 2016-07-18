FROM alpine:3.4

MAINTAINER Guillem CANAL <hello@guillem.ninja> 

ENV S6VERSION 1.17.2.0
ENV PATH=/.composer/vendor/bin:$PATH

COPY rootfs /

RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --update \
    wget \
    ca-certificates \
    openssh \
    nginx \
    php5-fpm \
    php5-json \
    php5-zlib \
    php5-bz2 \
    php5-bcmath \
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
    su-exec \
    bash \
    git \
    shadow@testing \

    # Modify nginx user

    && touch /var/lib/nginx/.bashrc \
    && echo "umask 0002" >> /var/lib/nginx/.bashrc \
    && mkdir /var/lib/nginx/.composer \
    && chown nginx:nginx -R /var/lib/nginx \

    # Build extensions

    && build-php-extensions \

    # Install S6

    && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6VERSION}/s6-overlay-amd64.tar.gz -O /tmp/s6-overlay.tar.gz \
    && tar xvfz /tmp/s6-overlay.tar.gz -C / \
    && rm -f /tmp/s6-overlay.tar.gz \

    # Install composer

    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/sbin --filename=composer \
    && php -r "unlink('composer-setup.php');" \

    ## Install global PHP utilities

    && composer global require friendsofphp/php-cs-fixer \
    && composer global require phing/phing \
    && composer global require sensiolabs/security-checker \

    # SSH 

    && echo -e "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile=/dev/null\n" > /etc/ssh/ssh_config \

    # Cleanup

    && rm -r /var/www/localhost \
    && apk del wget \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && rm -rf /usr/share/* \
    && rm -rf /root/.composer/cache

# Set working directory
WORKDIR /var/www

# Expose the ports for nginx
EXPOSE 80 443

ENTRYPOINT [ "/init" ]