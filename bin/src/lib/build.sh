touchConfigFile () {

  if [[ $1 =~ "php" ]]; then
    configFile="${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/etc/php/php.ini"
  fi

  if [[ $1 =~ mysql|percona|mariadb ]]; then
    configFile="${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/etc/my.cnf"
  fi

  if [[ $1 =~ "ssh" ]]; then
    configFile="${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/tunnel.conf"
  fi

  if [[ $1 =~ "nginx" ]]; then
      configFile="${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/etc/nginx/conf.d/default.conf"
  fi

  if [[ $1 =~ "varnish" ]]; then
    configFile="${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/default.vcl"
  fi

  if [[ -n "${configFile}" && ! -f "${configFile}" ]]; then
    echo "Touching ${configFile} before startup, because it does not exist"
    touch "${configFile}"
    if [[ $1 =~ "php" ]]; then
      echo 'Copying ini files, adopt to your needs'
      cp "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/sample/conf.d/*.ini" \
         "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/etc/php/conf.d"
    fi
    if [[ $1 =~ "nginx" ]]; then
        echo 'Copying config files, adopt to your needs'
        cp -R "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/sample/conf.d/default.conf" \
            "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/etc/nginx/conf.d"
    fi
    if [[ $1 =~ "varnish" ]]; then
        echo 'Copying config files, adopt to your needs'
        cp "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/sample/default.vlc" \
            "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/etc/varnish/"
    fi
  fi
}
