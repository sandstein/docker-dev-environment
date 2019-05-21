FROM sandstein/php:fpm-7.0

COPY env/bin/modify-user-ids /usr/local/bin/modify-user-ids

ARG USER_ID=33
ARG GROUP_ID=33
RUN modify-user-ids www-data ${USER_ID} ${GROUP_ID}

ARG DISABLED_PHP_FPM_MODULES
RUN disable-php-modules ${DISABLED_PHP_FPM_MODULES}
