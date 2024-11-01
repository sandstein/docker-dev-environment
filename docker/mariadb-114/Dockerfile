FROM sandstein/mariadb:11.4

ARG USER_ID=999
ARG GROUP_ID=999
RUN userdel ubuntu
RUN modify-user-ids mysql ${USER_ID} ${GROUP_ID}
