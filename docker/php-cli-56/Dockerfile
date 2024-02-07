FROM sandstein/php:cli-5.6

COPY env/* /home/phpcli/

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN chown phpcli.phpcli /home/phpcli/.[a-zA-Z]*  \
    && modify-user-ids phpcli ${USER_ID} ${GROUP_ID}

ENV PATH "/home/phpcli/bin:$PATH"

VOLUME /usr/local/etc/php /home/phpcli/bin

