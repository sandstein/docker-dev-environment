FROM bitnami/php-fpm:7.2-debian-9

# Workarround for sophos @see https://github.com/jenkinsci/docker/issues/543
RUN echo " \n\
Acquire::http::Pipeline-Depth 0; \n\
Acquire::http::No-Cache true; \n\
Acquire::BrokenProxy    true; \n\
" >  /etc/apt/apt.conf.d/99fixbadproxy

RUN apt-get update && \
    apt-get install -y --no-install-recommends git zip unzip curl

RUN curl --silent --show-error https://getcomposer.org/installer | php
