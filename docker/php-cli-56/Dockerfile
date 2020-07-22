FROM sandstein/php:cli-5.6

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids phpcli ${USER_ID} ${GROUP_ID}

ENV PATH "/home/phpcli/bin:$PATH"

VOLUME /usr/local/etc/php /home/phpcli/bin

