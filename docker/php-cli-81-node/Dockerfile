FROM sandstein/php:cli-8.1

RUN set -x \
    && apt-update  > /dev/null\
    && apt-install \
        nodejs \
        npm

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids phpcli ${USER_ID} ${GROUP_ID}

ENV PATH "/home/phpcli/bin:$PATH"

VOLUME /usr/local/etc/php /home/phpcli/bin
