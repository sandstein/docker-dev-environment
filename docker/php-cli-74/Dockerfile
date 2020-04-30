FROM sandstein/php:cli-7.4

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids phpcli ${USER_ID} ${GROUP_ID}

ARG DISABLED_PHP_CLI_MODULES
RUN disable-php-modules ${DISABLED_PHP_CLI_MODULES}
