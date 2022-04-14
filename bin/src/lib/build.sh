touchConfigFile () {

  if [[ $1 =~ "php" ]]; then
    part="${1/-x//}"
    configFile="${DOCKER_DEV_ENVIRONMENT_HOME}/config/$part/etc/php/php.ini"
  fi

  if [[ $1 =~ mysql|percona|mariadb ]]; then
    configFile="${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/etc/my.cnf"
  fi

  if [[ $1 =~ "ssh" ]]; then
    configFile="${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/tunnel.conf"
  fi

  if [[ -n "${configFile}" && ! -f "${configFile}" ]]; then
    echo "Touching ${configFile} before startup, because it does not exist"
    touch "${configFile}"
    if [[ $part =~ "php" ]]; then
      echo 'Copying ini files, adopt to your needs'
      cp "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$part/sample/conf.d/*.ini" \
         "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$part/etc/php/conf.d"
    fi
  fi
}
