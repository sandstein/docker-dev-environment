green "Listing all defined services:"
${DOCKER_COMPOSE_COMMAND} -f "${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml" config --services
