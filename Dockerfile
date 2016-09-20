FROM alpine:3.4

MAINTAINER Guillem CANAL <hello@guillem.ninja> 

ENV S6VERSION 1.17.2.0
ENV PATH=/.composer/vendor/bin:$PATH

COPY rootfs /

RUN apk add --update \
    wget \
    ca-certificates \
    openssh \
    nginx \
    php5-fpm \  
    php5-json \
    php5-xml \
    php5-phar \
    php5-openssl \
    php5-mcrypt \
    php5-dom \
    php5-opcache \
    php5-curl \
    git \

    # Configure PHP

    && echo "memory_limit=-1" >> /etc/php5/conf.d/docker.ini \
    && echo "date.timezone=Europe/Paris" >> /etc/php5/conf.d/docker.ini \
    && echo -e "\n[XDebug]\nxdebug.idekey=\"docker\"\nxdebug.remote_enable=On\nxdebug.remote_connect_back=On\nxdebug.remote_autostart=Off" >> /etc/php5/conf.d/docker.ini \

    # Configure SSHD server

    && ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa \
    && echo -e "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile=/dev/null\n" > /etc/ssh/ssh_config \

    # Create docker user
    
    && adduser -u 1000 -D -s /bin/ash docker \
    && echo "docker:docker" | chpasswd \

    # Install composer

    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/sbin --filename=composer \
    && php -r "unlink('composer-setup.php');" \

    # Install S6

    && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6VERSION}/s6-overlay-amd64.tar.gz -O /tmp/s6-overlay.tar.gz \
    && tar xvfz /tmp/s6-overlay.tar.gz -C / \
    && rm -f /tmp/s6-overlay.tar.gz \

    # Build extensions

    && build-php-extensions \

    # Cleanup

    && rm -r /var/www \
    && apk del wget \
    && rm -rf /usr/share/* \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && rm -rf /root/.composer/cache

VOLUME ["/var/www"]

# Expose the ports for nginx
EXPOSE 80 443 22 9000

ENTRYPOINT [ "/init" ]