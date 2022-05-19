parse_command_args
if [ -v WARNING ]; then
    red "${WARNING}"
    red "${ENV_WARNING}"
else
       while IFS=',' read -ra CONTAINER; do
          for container in "${CONTAINER[@]}"; do
              if [ -v "args[--restart]" ]; then
                  docker-compose -f ${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml stop ${container}
              fi
              touchConfigFile ${container}
              docker-compose -f ${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml up -d ${container}
          done
       done <<< "${CONTAINER_LIST}"
fi
