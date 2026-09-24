init_rc() {
  local target_file="$1"

  if [[ -z "${target_file}" ]]; then
    red "Error: Target file is not provided to init_rc"
    exit 1
  fi

  cat >> "${target_file}" <<EOL_SH
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
if [[ -f "${DOCKER_DEV_ENVIRONMENT_HOME}/bin/completions.bash" ]]; then
    . "${DOCKER_DEV_ENVIRONMENT_HOME}/bin/completions.bash"
fi
EOL_PATH
}
