FROM sandstein/php:fpm-5.6

ARG USER_ID=33
ARG GROUP_ID=33
RUN modify-user-ids www-data ${USER_ID} ${GROUP_ID}

VOLUME /usr/local/etc/php
