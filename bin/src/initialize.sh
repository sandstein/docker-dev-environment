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
if [ -f "${PWD}/.env" ]; then
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

# parses the command args
function parse_command_args() {

    # determine working dir
    if [ -v "args[--default-working-dir]" ]; then
        WORKINGDIRPART=""
    elif [ -v "PROJECT_ROOT" ]; then
        WORKINGDIRPART="-w /var/www/vhosts/${PROJECT_ROOT}"
    else
        WORKINGDIRPART=""
    fi

    # set root user if desired
    if [ -v "args[--root]" ]; then
        USERPART="-u root"
    else
        USERPART="-u ${USER_ID}"
    fi

    # create new container if desired
    if [ -v "args[--run]" ]; then
        MODEPART="run --rm"
    else
        MODEPART="exec"
    fi

    # seek default container for dde bash
    if [ -v "args[container]" ]; then
        CONTAINER="${args[container]}"
    # inspect PHP_CLI_CONTAINER for backward compatibility
    elif [ -v "PHP_CLI_CONTAINER" ]; then
        CONTAINER="${PHP_CLI_CONTAINER}"
    elif [ -v "DEFAULT_CONTAINER" ]; then
        CONTAINER="${DEFAULT_CONTAINER}"
    else
        WARNING="Could not determine the container!"
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
        WARNING="No container given!"
    fi

    # sets the build options
    BUILD_OPTIONS="--force-rm --pull --no-cache"
}


