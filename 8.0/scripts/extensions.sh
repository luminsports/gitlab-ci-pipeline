#!/usr/bin/env bash

set -euo pipefail

if [[ $PHP_VERSION == "8.0" ]]; then
export extensions=" \
  bcmath \
  bz2 \
  calendar \
  exif \
  gmp \
  intl \
  mysqli \
  opcache \
  pcntl \
  pdo_mysql \
  pdo_pgsql \
  pgsql \
  soap \
  xsl \
  zip
  "
else
  export extensions=" \
  bcmath \
  bz2 \
  calendar \
  exif \
  gmp \
  intl \
  mysqli \
  opcache \
  pcntl \
  pdo_mysql \
  pdo_pgsql \
  pgsql \
  soap \
  xmlrpc \
  xsl \
  zip
  "
fi

if [[ $PHP_VERSION == "8.0" || $PHP_VERSION == "7.4" || $PHP_VERSION == "7.3" || $PHP_VERSION == "7.2" ]]; then

export buildDeps=" \
    default-libmysqlclient-dev \
    libbz2-dev \
    libsasl2-dev \
    pkg-config \
    "

export runtimeDeps=" \
    freetds-bin \
    freetds-dev \
    freetds-common \
    imagemagick \
    libfreetype6-dev \
    libgmp-dev \
    libicu-dev \
    libjpeg-dev \
    libkrb5-dev \
    libldap2-dev \
    libmagickwand-dev \
    libmemcached-dev \
    libmemcachedutil2 \
    libpng-dev \
    libpq-dev \
    librabbitmq-dev \
    libssl-dev \
    libsybdb5 \
    libuv1-dev \
    libwebp-dev \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    msodbcsql17 \
    multiarch-support \
    unixodbc-dev \
    "
else

export buildDeps=" \
    default-libmysqlclient-dev \
    libbz2-dev \
    libsasl2-dev \
    "

export runtimeDeps=" \
    imagemagick \
    libfreetype6-dev \
    libgmp-dev \
    libicu-dev \
    libjpeg-dev \
    libkrb5-dev \
    libldap2-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libmemcachedutil2 \
    libpng-dev \
    libpq-dev \
    librabbitmq-dev \
    libuv1-dev \
    libwebp-dev \
    libxml2-dev \
    mcrypt \
    multiarch-support \
    "
fi

ACCEPT_EULA=Y

apt-get update \
  && apt-get install -yq --no-install-recommends $buildDeps \
  && apt-get install -yq --no-install-recommends $runtimeDeps \
  && rm -rf /var/lib/apt/lists/* \
  && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/ \
  && docker-php-ext-install -j$(nproc) $extensions

docker-php-source extract \
    && { \
        echo '# https://github.com/docker-library/php/issues/103#issuecomment-271413933'; \
        echo 'AC_DEFUN([PHP_ALWAYS_SHARED],[])dnl'; \
        echo; \
        cat /usr/src/php/ext/odbc/config.m4; \
    } > temp.m4 \
    && mv temp.m4 /usr/src/php/ext/odbc/config.m4 \
    && curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -L https://packages.microsoft.com/config/debian/10/prod.list -o /etc/apt/sources.list.d/mssql-release.list \
    && docker-php-ext-install odbc pdo_dblib \
    && docker-php-source delete

if [[ $PHP_VERSION == "8.0" || $PHP_VERSION == "7.4" ]]; then
    docker-php-ext-configure odbc --with-unixODBC=shared,/usr \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) ldap \
    && PHP_OPENSSL=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) imap \
    && docker-php-source delete
else
    docker-php-ext-configure odbc --with-unixODBC=shared,/usr \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-webp-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) imap \
    && docker-php-source delete
fi

docker-php-source extract \
    && curl -L -o /tmp/cassandra-cpp-driver.deb "https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.14.0/cassandra-cpp-driver_2.14.0-1_amd64.deb" \
    && curl -L -o /tmp/cassandra-cpp-driver-dev.deb "https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.14.0/cassandra-cpp-driver-dev_2.14.0-1_amd64.deb" \
    && dpkg -i /tmp/cassandra-cpp-driver.deb /tmp/cassandra-cpp-driver-dev.deb \
    && rm /tmp/cassandra-cpp-driver.deb /tmp/cassandra-cpp-driver-dev.deb \
    && curl -L -o /tmp/cassandra.tar.gz "https://github.com/datastax/php-driver/archive/24d85d9f1d.tar.gz" \
    && mkdir /tmp/cassandra \
    && tar xfz /tmp/cassandra.tar.gz --strip 1 -C /tmp/cassandra \
    && rm -r /tmp/cassandra.tar.gz \
    && curl -L "https://github.com/datastax/php-driver/pull/135.patch" | patch -p1 -d /tmp/cassandra -i - \
    && mv /tmp/cassandra/ext /usr/src/php/ext/cassandra \
    && rm -rf /tmp/cassandra \
    && docker-php-ext-install cassandra \
    && docker-php-source delete

if [[ $PHP_VERSION == "7.2" ]]; then
  docker-php-source extract \
    && git clone https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached/ \
    && docker-php-ext-install memcached \
    && docker-php-source delete

  pecl channel-update pecl.php.net \
    && pecl install amqp redis apcu mongodb imagick xdebug sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable amqp redis apcu mongodb imagick xdebug sqlsrv pdo_sqlsrv

elif [[ $PHP_VERSION == "8.0" || $PHP_VERSION == "7.4" || $PHP_VERSION == "7.3" ]]; then
  docker-php-source extract \
    && git clone https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached/ \
    && docker-php-ext-install memcached \
    && docker-php-ext-enable memcached \
    && docker-php-source delete

  pecl channel-update pecl.php.net \
    && pecl install amqp redis apcu mongodb imagick xdebug sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable amqp redis apcu mongodb imagick xdebug sqlsrv pdo_sqlsrv

else
  apt-get update && docker-php-ext-install -j$(nproc) mcrypt
  pecl channel-update pecl.php.net \
    && pecl install amqp redis mongodb xdebug apcu memcached imagick sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable amqp redis mongodb xdebug apcu memcached imagick sqlsrv pdo_sqlsrv
fi

{ \
    echo 'opcache.enable=1'; \
    echo 'opcache.revalidate_freq=0'; \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.memory_consumption=192'; \
    echo 'opcache.max_wasted_percentage=10'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.fast_shutdown=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

{ \
    echo 'apc.shm_segments=1'; \
    echo 'apc.shm_size=1024M'; \
    echo 'apc.num_files_hint=7000'; \
    echo 'apc.user_entries_hint=4096'; \
    echo 'apc.ttl=7200'; \
    echo 'apc.user_ttl=7200'; \
    echo 'apc.gc_ttl=3600'; \
    echo 'apc.max_file_size=100M'; \
    echo 'apc.stat=1'; \
} > /usr/local/etc/php/conf.d/apcu-recommended.ini

echo 'memory_limit=1024M' > /usr/local/etc/php/conf.d/zz-conf.ini
echo 'xdebug.coverage_enable=1' > /usr/local/etc/php/conf.d/20-xdebug.ini

apt-get purge -yqq --auto-remove $buildDeps