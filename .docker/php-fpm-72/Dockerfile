FROM bitnami/php-fpm:7.2-debian-9

RUN apt-get update && \
    apt-get install -y --no-install-recommends git zip unzip curl

RUN curl --silent --show-error https://getcomposer.org/installer | php
