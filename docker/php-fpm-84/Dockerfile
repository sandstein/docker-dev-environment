FROM sandstein/php:fpm-8.4

ARG USER_ID=33
ARG GROUP_ID=33
RUN modify-user-ids www-data ${USER_ID} ${GROUP_ID}

VOLUME /usr/local/etc/php
