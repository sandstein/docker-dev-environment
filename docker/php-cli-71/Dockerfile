FROM sandstein/php:cli-7.1

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN chown phpcli.phpcli /home/phpcli/.[a-zA-Z]*  \
    && modify-user-ids phpcli ${USER_ID} ${GROUP_ID}
ENV PATH "/home/phpcli/bin:$PATH"

VOLUME /usr/local/etc/php /home/phpcli/bin
