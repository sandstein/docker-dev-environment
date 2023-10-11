parse_command_args
if [ -v CONTAINER_WARNING ]; then
    red "${CONTAINER_WARNING}"
    red "${ENV_WARNING}"
else
       while IFS=',' read -ra CONTAINER; do
          for container in "${CONTAINER[@]}"; do
              if [ -v "args[--restart]" ]; then
                 ${DOCKER_COMPOSE_COMMAND} -f "${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml" stop ${container}
              fi
              touchConfigFile "${container}"
             ${DOCKER_COMPOSE_COMMAND} -f "${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml" up -d ${container}
          done
       done <<< "${CONTAINER_LIST}"
fi
