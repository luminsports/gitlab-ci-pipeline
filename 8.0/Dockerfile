FROM php:8.0 as builder

ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="Eduardo Bizarro <edbizarro@gmail.com>" \
  PHP="8.0" \
  NODE="15" \
  org.label-schema.name="edbizarro/gitlab-ci-pipeline-php" \
  org.label-schema.description=":coffee: Docker images for build and test PHP applications with Gitlab CI (or any other CI plataform!)" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.schema-version="1.0" \
  org.label-schema.vcs-url="https://github.com/edbizarro/gitlab-ci-pipeline-php" \
  org.label-schema.vcs-ref=$VCS_REF

# Set correct environment variables
ENV IMAGE_USER=php
ENV HOME=/home/$IMAGE_USER
ENV COMPOSER_HOME=$HOME/.composer
ENV PATH=$HOME/.yarn/bin:$PATH
ENV GOSS_VERSION="0.3.16"
ENV PHP_VERSION=8.0

USER root

WORKDIR /tmp

# COPY INSTALL SCRIPTS
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY ./scripts/*.sh /tmp/
RUN chmod +x /tmp/*.sh

# Install2
RUN bash ./packages.sh \
  && bash ./extensions.sh \
  && bash ./node.sh \
  && adduser --disabled-password --gecos "" $IMAGE_USER && \
  echo "PATH=$(yarn global bin):$PATH" >> /root/.profile && \
  echo "PATH=$(yarn global bin):$PATH" >> /root/.bashrc && \
  echo "$IMAGE_USER  ALL = ( ALL ) NOPASSWD: ALL" >> /etc/sudoers && \
  mkdir -p /var/www/html \
  && rm -rf ~/.composer/cache/* \
  && chown -R $IMAGE_USER:$IMAGE_USER /var/www $HOME \
  && curl -fsSL https://goss.rocks/install | GOSS_VER=v${GOSS_VERSION} sh \
  && bash ./cleanup.sh

USER $IMAGE_USER

WORKDIR /var/www/html

FROM builder

USER root

RUN set -ex \
    && docker-php-source extract \
    && { \
        echo '# https://github.com/docker-library/php/issues/103#issuecomment-271413933'; \
        echo 'AC_DEFUN([PHP_ALWAYS_SHARED],[])dnl'; \
        echo; \
        cat /usr/src/php/ext/odbc/config.m4; \
    } > temp.m4 \
    && mv temp.m4 /usr/src/php/ext/odbc/config.m4 \
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
    && pecl install sqlsrv-5.9.0beta2 pdo_sqlsrv-5.9.0beta2 \
    && docker-php-ext-configure odbc --with-unixODBC=shared,/usr \
    && docker-php-ext-install odbc pdo_dblib \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    && docker-php-source delete \
    && apt-get purge -y --auto-remove \
    && composer global require laravel/vapor-cli \
    && rm -rf ~/.composer/cache/* \
    && chown -R $IMAGE_USER:$IMAGE_USER /var/www $HOME

USER $IMAGE_USER
