#inspect_args
parse_command_args
if [ -v SERVICE_WARNING ]; then
    red "${SERVICE_WARNING}"
    red "${ENV_WARNING}"
else
   ${DOCKER_COMPOSE_COMMAND} -f "${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml" "${MODEPART[@]}" \
        "${USERPART[@]}" "${WORKINGDIRPART[@]}" "${SERVICE}" bash
fi
