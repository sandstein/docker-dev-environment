green "Listing all defined services"
echo
docker-compose  -f ${DOCKER_DEV_ENVIRONMENT_HOME}/docker-compose.yml config --service
echo
green "Done"
