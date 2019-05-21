FROM sandstein/apache:2.4

COPY config/apache-24/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY env/bin/modify-user-ids /usr/local/bin/modify-user-ids

VOLUME /var/www/vhosts

ARG USER_ID=33
ARG GROUP_ID=33
RUN modify-user-ids www-data ${USER_ID} ${GROUP_ID}
