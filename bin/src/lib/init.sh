init_rc() {

  cat >> "${BASHRC_FILE}" <<EOL_SH
#
# initialising docker dev environment
#
source ~/.docker/.dderc
EOL_SH
}

init_path() {
    cat > ~/.docker/.dderc <<EOL_PATH
#
# initialising docker dev environment
#
export DOCKER_DEV_ENVIRONMENT_HOME="${REQUESTED_DOCKER_DEV_ENVIRONMENT_HOME}"
if [[ -d "\${DOCKER_DEV_ENVIRONMENT_HOME}/bin" ]]; then
    PATH="\${DOCKER_DEV_ENVIRONMENT_HOME}/bin:\${PATH}"
fi
EOL_PATH
}
