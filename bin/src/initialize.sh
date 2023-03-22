# use extended globbing
shopt -s extglob

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

# parses the command args
# see https://github.com/koalaman/shellcheck/wiki/SC2086 for argument parsing in shell
function parse_command_args() {

    # determine working dir
    if [ -v "args[--default-working-dir]" ]; then
        WORKINGDIRPART=()
    elif [ -v "args[--working-dir]" ]; then
        WORKINGDIRPART=(-w "${args[--working-dir]}")
    elif [ -v "PROJECT_ROOT" ]; then
        WORKINGDIRPART=(-w /var/www/vhosts/${PROJECT_ROOT})
    else
        VHOSTS_BASE=$(realpath "${DOCKER_DEV_ENVIRONMENT_HOME}"/vhosts)
        REL_PATH=${PWD#@($VHOSTS_BASE/)}
        WORKINGDIRPART=(-w "/var/www/vhosts/${REL_PATH}")
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


