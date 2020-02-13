FROM php:7.3-fpm-alpine3.11
RUN set -ex; \
    \
    export CFLAGS="-Os"; \
    export CPPFLAGS="${CFLAGS}"; \
    export LDFLAGS="-Wl,--strip-all"; \
    \
    # Runtime dependencies
    apk add --no-cache \
        c-client \
        icu \
        libintl \
        libpng \
        libzip \
        msmtp \
        nginx \
        openldap \
        runit \
    ; \
    \
    # Build dependencies
    apk add --no-cache --virtual .build-deps \
        ${PHPIZE_DEPS} \
        gettext-dev \
        icu-dev \
        imap-dev \
        libpng-dev \
        libzip-dev \
        openldap-dev \
    ; \
    \
    # Install PHP extensions
    docker-php-ext-configure imap --with-imap-ssl; \
    docker-php-ext-install -j "$(nproc)" \
        gd \
        gettext \
        imap \
        intl \
        ldap \
        mysqli \
        sockets \
        zip \
    ; \
    pecl install apcu; \
    docker-php-ext-enable \
        apcu \
        opcache \
    ; \
    \
    # Create msmtp log
    touch /var/log/msmtp.log; \
    chown www-data:www-data /var/log/msmtp.log; \
    \
    # Create data dir
    mkdir /var/lib/osticket; \
    \
    # Clean up
    apk del .build-deps; \
    rm -rf /tmp/pear /var/cache/apk/*

COPY src /usr/local/src/osticket

RUN set -ex; \
    \
    mkdir /usr/local/src/osticket; \
    # Hard link the sources to the public directory
    cp -al /usr/local/src/osticket/. /var/www/html; \
    # Hide setup
    rm -r /var/www/html/setup; \
    \
    for lang in ar az bg ca cs da de el es_ES et fr hr hu it ja ko lt mk mn nl no fa pl pt_PT \
        pt_BR sk sl sr_CS fi sv_SE ro ru vi th tr uk zh_CN zh_TW; do \
        wget -q -O /var/www/html/include/i18n/${lang}.phar \
            https://s3.amazonaws.com/downloads.osticket.com/lang/${lang}.phar; \
    done
ENV OSTICKET_PLUGINS_VERSION=6ba7e511e7d24c73603be88e51f13b035ca8a79c \
    OSTICKET_PLUGINS_SHA256SUM=a6ca85c960d13d07192aa2864845ff4d7cc356d6460ec2465e0b9332e2de899d
RUN set -ex; \
    \
    wget -q -O osTicket-plugins.tar.gz https://github.com/devinsolutions/osTicket-plugins/archive/\
${OSTICKET_PLUGINS_VERSION}.tar.gz; \
    echo "${OSTICKET_PLUGINS_SHA256SUM}  osTicket-plugins.tar.gz" | sha256sum -c; \
    tar -xzf osTicket-plugins.tar.gz --one-top-level --strip-components 1; \
    rm osTicket-plugins.tar.gz; \
    \
    cd osTicket-plugins; \
    php make.php hydrate; \
    find * -maxdepth 0 -type d ! -path doc ! -path lib -exec mv '{}' \
        /var/www/html/include/plugins +; \
    cd ..; \
    \
    rm -r osTicket-plugins /root/.composer
ENV OSTICKET_SLACK_VERSION=cd98e54fcadf1a5dd8e78b0a0380561c7ef29b02 \
    OSTICKET_SLACK_SHA256SUM=9cdead701fd1be91a64451dfaca98148b997dc4e5a0ff1a61965bffeebd65540
RUN set -ex; \
    \
    wget -q -O osTicket-slack-plugin.tar.gz https://github.com/devinsolutions/\
osTicket-slack-plugin/archive/${OSTICKET_SLACK_VERSION}.tar.gz; \
    echo "${OSTICKET_SLACK_SHA256SUM}  osTicket-slack-plugin.tar.gz" | sha256sum -c; \
    tar -xzf osTicket-slack-plugin.tar.gz -C /var/www/html/include/plugins --strip-components 1 \
        osTicket-slack-plugin-${OSTICKET_SLACK_VERSION}/slack; \
    rm osTicket-slack-plugin.tar.gz

COPY docker/root /
CMD ["start"]
STOPSIGNAL SIGTERM
EXPOSE 80
HEALTHCHECK CMD curl -fIsS http://localhost/ || exit 1
