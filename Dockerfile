FROM alpine:edge

MAINTAINER Guillem CANAL <hello@guillem.ninja> 

ENV S6VERSION="1.17.2.0" \
    PATH="/.composer/vendor/bin:$PATH" \
    COMPOSER_HOME="/composer" \
    JAVA_VERSION_MAJOR="8" \
    JAVA_VERSION_MINOR="102" \
    JAVA_VERSION_BUILD="14" \
    JAVA_PACKAGE="server-jre" \
    JAVA_JCE="standard" \
    JAVA_HOME="/opt/jdk" \
    PATH="${PATH}:/opt/jdk/bin" \
    GLIBC_VERSION="2.23-r3" \
    LANG="C.UTF-8" \
    NODE_VERSION="v6.3.1" \
    NPM_VERSION="3" \
    NODE_CONFIG_FLAGS="--fully-static" \
    NODE_DEL_PKGS="libgcc libstdc++" \
    NODE_RM_DIRS="/usr/include"

COPY rootfs /

RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --update \
    build-base \
    wget \
    ca-certificates \
    openssh \
    nginx \
    su-exec \
    bash \
    git \
    grep \

    # Install PHP
    
    php5-fpm \
    php5-json \
    php5-zlib \
    php5-xml \
    php5-intl \
    php5-phar \
    php5-openssl \
    php5-mcrypt \
    php5-dom \
    php5-ctype \
    php5-opcache \
    php5-curl \
    php5-memcache \
    php5-xdebug@testing \

    # Install Ruby
    
    ruby \
    ruby-dev \
    libffi-dev \

    # Install Node
    
    nodejs \

    # Build PHP extensions
    
    && /sbin/build-php-extensions \

    # Install Ruby/Node deps
    
    && gem install --no-ri --no-rdoc compass \
    && npm install -g grunt-cli bower \

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

    # Cleanup

    && rm -r /var/www/localhost \
    && apk del wget build-base ruby-dev libffi-dev \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    # && rm -rf /usr/share/* \
    && rm -rf /root/.composer/cache \

	# Install JAVA used to minify assets

	&& apk upgrade --update && \
    apk add --update libstdc++ curl bash && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    mkdir -p /opt && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
      http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz && \
    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
      http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
    gunzip /tmp/java.tar.gz && \
    tar -C /opt -xf /tmp/java.tar && \
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    find /opt/jdk/ -maxdepth 1 -mindepth 1 | grep -v jre | xargs rm -rf && \
    cd /opt/jdk/ && ln -s ./jre/bin ./bin && \
    if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" && \
      curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
        http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cd /tmp && unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar /opt/jdk/jre/lib/security/; \
    fi && \
    sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=30/ $JAVA_HOME/jre/lib/security/java.security && \
    apk del curl glibc-i18n && \
    rm -rf /opt/jdk/jre/plugin \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/bin/jjs \
           /opt/jdk/jre/bin/keytool \
           /opt/jdk/jre/bin/orbd \
           /opt/jdk/jre/bin/pack200 \
           /opt/jdk/jre/bin/policytool \
           /opt/jdk/jre/bin/rmid \
           /opt/jdk/jre/bin/rmiregistry \
           /opt/jdk/jre/bin/servertool \
           /opt/jdk/jre/bin/tnameserv \
           /opt/jdk/jre/bin/unpack200 \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/lib/ext/nashorn.jar \
           /opt/jdk/jre/lib/oblique-fonts \
           /opt/jdk/jre/lib/plugin.jar \
           /tmp/* /var/cache/apk/* && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# Set working directory
WORKDIR /var/www

# Expose the ports for nginx
EXPOSE 80 443 22 9000

ENTRYPOINT [ "/init" ]