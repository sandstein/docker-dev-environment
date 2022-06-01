FROM sandstein/ssh

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids ssh ${USER_ID} ${GROUP_ID}

USER ssh
