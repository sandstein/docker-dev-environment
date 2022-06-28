# where is this file located
SCRIPT_PATH=$(readlink -f "$0")
MY_PATH=$(dirname "$SCRIPT_PATH")

#
# sets DOCKER_DEV_ENVIRONMENT_HOME
#
if [ -z "${DOCKER_DEV_ENVIRONMENT_HOME+x}" ]; then
    magenta "Warning: dde not initialised, use dde init to do so"
fi

# initializes the dde wide variables like user id etc.
# see .env.sample
#
if [ -f "${MY_PATH}/../.env" ]; then
 set -a
 . "${MY_PATH}/../.env"
 set +a
else
  echo "Please copy the file .env.sample file inside your docker-dev-environment to .env and change according to your needs"
  exit 1
fi

# initializes the specific container needs for a given project
# see .env.project-sample
if [ -f "${PWD}/.env.dde" ]; then
  set -a
  . "${PWD}/.env.dde"
  set +a
elif [ -f "${PWD}/.env" ]; then
  set -a
  . "${PWD}/.env"
  set +a
elif [ "${DOCKER_DEV_ENVIRONMENT_HOME}" != "${PWD}" ]; then
  ENV_WARNING="Warning: there is no .env in your current working dir. Wrong pwd or missing project initialisation?"
fi

# creates an empty config file for services which are started
# for the first time.
# for php container a sample php.ini is copied
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

  if [[ $1 =~ "opensearch" ]]; then
    part="${1/-x//}"
    configFile="${DOCKER_DEV_ENVIRONMENT_HOME}/config/$1/config/initialized"
  fi

  if [[ -n "${configFile}" && ! -f "${configFile}" ]]; then
    echo "Touching ${configFile} before startup, because it does not exist"
    touch "${configFile}"
    if [[ $part =~ "php" ]]; then
      echo 'Copying ini files, adopt to your needs'
      cp "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$part"/sample/conf.d/*.ini \
         "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$part"/etc/php/conf.d
    fi
    if [[ $part =~ "opensearch" ]]; then
        echo 'Copying config files, adopt to your needs'
        cp -R "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$part"/sample/* \
              "${DOCKER_DEV_ENVIRONMENT_HOME}/config/$part"/config
    fi
  fi
}

# parses the command args
# see https://github.com/koalaman/shellcheck/wiki/SC2086 for argument parsing in shell
function parse_command_args() {

    # determine working dir
    if [ -v "args[--default-working-dir]" ]; then
        WORKINGDIRPART=()
    elif [ -v "PROJECT_ROOT" ]; then
        WORKINGDIRPART=(-w /var/www/vhosts/${PROJECT_ROOT})
    else
        WORKINGDIRPART=()
    fi

    # set root user if desired
    if [ -v "args[--root]" ]; then
        USERPART=(-u root)
    else
        USERPART=(-u ${USER_ID})
    fi

    # determine run type

    if [ -v "args[--run]" ]; then
        MODEPART=(run --rm)
    else
        MODEPART=(exec)
    fi

    #
    if [ -v "args[--no-tty]" ]; then
        TTYPART=(-T)
    else
        TTYPART=()
    fi

    # seek default service for command execution
    if [ -v "args[--service]" ]; then
        SERVICE="${args[--service]}"
    # inspect PHP_CLI_CONTAINER for backward compatibility
    elif [ -v "PHP_CLI_CONTAINER" ]; then
        SERVICE="${PHP_CLI_CONTAINER}"
    elif [ -v "DEFAULT_CONTAINER" ]; then
        SERVICE="${DEFAULT_CONTAINER}"
    else
        SERVICE_WARNING="Could not determine the service to execute the command on!"
    fi


    # prepares the container list for dde start and dde build
    if [ -v "args[container]" ]; then
        CONTAINER_LIST="${args[container]}"
    elif [ -v "DOCKER_CONTAINER" ]; then
        CONTAINER_LIST="${DOCKER_CONTAINER}"
        # inspect PHP_FPM_CONTAINER for backward compatibility
        if [ -v "PHP_FPM_CONTAINER" ]; then
            CONTAINER_LIST="${CONTAINER_LIST},${PHP_FPM_CONTAINER}"
        fi
    else
        CONTAINER_WARNING="No container given!"
    fi

    if [ -v "args[command]" ]; then
        IFS=" " read -ra COMMAND<<<"${args[command]}"
    fi
}

