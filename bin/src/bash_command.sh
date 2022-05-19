#inspect_args
parse_command_args
if [ -v WARNING ]; then
    red "${WARNING}"
    red "${ENV_WARNING}"
else
    docker-compose -f ${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml ${MODEPART} ${USERPART} ${WORKINGDIRPART} ${CONTAINER} bash
fi
