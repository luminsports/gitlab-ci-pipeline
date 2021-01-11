FROM edbizarro/gitlab-ci-pipeline-php:7.4

USER root

RUN set -ex \
    && curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -L https://packages.microsoft.com/config/debian/10/prod.list -o /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql17 \
        unixodbc-dev \
        freetds-bin \
        freetds-dev \
        freetds-common \
        libsybdb5 \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/ \
    && pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-configure odbc --with-unixODBC=shared,/usr \
    && docker-php-ext-install odbc pdo_dblib \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv  \
    && docker-php-source delete \
    && apt-get purge -y --auto-remove \
    && composer self-update --2 \
    && composer global remove hirak/prestissimo \
    && composer global require laravel/vapor-cli

USER $IMAGE_USER
