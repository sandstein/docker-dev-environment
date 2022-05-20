REQUESTED_DOCKER_DEV_ENVIRONMENT_HOME=$(readlink -f "${MY_PATH}/..")

#
# sets DOCKER_DEV_ENVIRONMENT_HOME
# if it is no set or changed
#
if [[ -z "${DOCKER_DEV_ENVIRONMENT_HOME+x}" || "${REQUESTED_DOCKER_DEV_ENVIRONMENT_HOME}" != "${DOCKER_DEV_ENVIRONMENT_HOME}" ]]; then

    BASHRC_FILE="${HOME}/.bashrc"
    #
    # check if source command is included in .bashrc if the file exists
    #
    if [[ -f $BASHRC_FILE  && "$(grep -c ".docker/.dderc" "${BASHRC_FILE}")" = "0" ]]; then
        init_rc
    fi

    ZSHRC_FILE="${HOME}/.zshrc"
    #
    # check if source command is included in .zshrc if the file exists
    #
    if [[ -f $ZSHRC_FILE  && "$(grep -c ".docker/.dderc" "${ZSHRC_FILE}")" = "0" ]]; then
        init_rc
    fi

    #
    # check if .devenvrc file exists
    #
    if [[ ! -d ~/.docker ]]; then
       mkdir ~/.docker
    fi

    if [[ ( ! -f ~/.docker/.dderc ) || "${REQUESTED_DOCKER_DEV_ENVIRONMENT_HOME}" != "${DOCKER_DEV_ENVIRONMENT_HOME}" ]]; then
        init_path
    fi

    green "docker dev environment initialized or changed, please type"
    if [[ "$(grep -c "/bash" "${SHELL}")" != "0" ]]; then
        green "$ source $BASHRC_FILE "
    elif [[ "$(grep -c "/zsh" "${SHELL}")" != "0" ]]; then
        green "$ source $ZSHRC_FILE "
    else
        green "$ source /pfad/zur/config/datei/der/shell "
    fi
    green "to see effects"
else
    magenta "docker dev environment already initialised"
fi
