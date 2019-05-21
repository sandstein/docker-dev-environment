FROM sandstein/percona:5.6

COPY env/bin/modify-user-ids /usr/local/bin/modify-user-ids

ARG USER_ID=999
ARG GROUP_ID=999
RUN modify-user-ids mysql ${USER_ID} ${GROUP_ID}
