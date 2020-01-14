FROM sandstein/php:cli-7.3

COPY env/bin/modify-user-ids /usr/local/bin/modify-user-ids

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids phpcli ${USER_ID} ${GROUP_ID}

ARG DISABLED_PHP_CLI_MODULES
RUN disable-php-modules ${DISABLED_PHP_CLI_MODULES}

RUN chown -R phpcli:phpcli /home/phpcli

RUN sed -i 's/SECLEVEL=2/SECLEVEL=1/g' /etc/ssl/openssl.cnf
