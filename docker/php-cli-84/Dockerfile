FROM sandstein/php:cli-8.4

COPY env/* /home/phpcli/

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN chown phpcli.phpcli /home/phpcli/.[a-zA-Z]*  \
    && modify-user-ids phpcli ${USER_ID} ${GROUP_ID}

COPY bashrc-snippet.sh /tmp/bashrc-snippet.sh
RUN cat /tmp/bashrc-snippet.sh >> /home/phpcli/.bashrc && \
    rm /tmp/bashrc-snippet.sh

ENV PATH "/home/phpcli/bin:$PATH"
EXPOSE 8082

VOLUME /usr/local/etc/php /home/phpcli/bin
