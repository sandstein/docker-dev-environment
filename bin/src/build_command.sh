parse_command_args
if [ -v "args[--all]" ]; then
    if [ -v "args[--restart]" ]; then
        red "You can not provide the two options together!"
    else
        docker-compose -f "${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml" build "${BUILD_OPTIONS}"
    fi
elif [ -v WARNING ]; then
    red "${WARNING}"
    red "${ENV_WARNING}"
else
       while IFS=',' read -ra CONTAINER; do
          for container in "${CONTAINER[@]}"; do
              docker-compose -f "${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml" build \
                 --force-rm --pull --no-cache "${container}"
              if [ -v "args[--restart]" ]; then
                  dde restart "${container}"
              fi
          done
       done <<< "${CONTAINER_LIST}"
fi


