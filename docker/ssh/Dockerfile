FROM sandstein/ssh

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN modify-user-ids ssh ${USER_ID} ${GROUP_ID}

COPY files/ssh-cmd.sh  /usr/local/bin/

USER ssh

CMD ["ssh-cmd.sh"]
