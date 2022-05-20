parse_command_args
if [ -v SERVICE_WARNING ]; then
    red "${SERVICE_WARNING}"
    red "${ENV_WARNING}"
else
    docker-compose -f "${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml" "${MODEPART[@]}" \
        "${TTYPART[@]}" "${USERPART[@]}" "${WORKINGDIRPART[@]}" "${SERVICE}" "${COMMAND[@]}"
fi
