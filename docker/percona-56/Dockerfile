FROM sandstein/percona:5.6

ARG USER_ID=999
ARG GROUP_ID=999
USER root
RUN modify-user-ids mysql ${USER_ID} ${GROUP_ID}
USER mysql
