## Code here runs inside the initialize() function
## Use it for anything that you need to run before any other function, like
## setting environment vairables:
## CONFIG_FILE=settings.ini
##
## Feel free to empty (but not delete) this file.

SCRIPT_PATH=$(readlink -f "$0")
MY_PATH=$(dirname "$SCRIPT_PATH")

#
# sets DOCKER_DEV_ENVIRONMENT_HOME
#
if [ -z "${DOCKER_DEV_ENVIRONMENT_HOME+x}" ]; then
    magenta "Warning: dde not initialised, use dde init to do so"
fi

if [ -f "${MY_PATH}/../.env" ]; then
 set -a
 . "${MY_PATH}/../.env"
 set +a
else
  echo "Please copy the file .env.sample file inside your docker-dev-environment to .env and change according to your needs"
  exit 1
fi

if [ -f "${PWD}/.env" ]; then
  set -a
  . "${PWD}/.env"
  set +a
elif [ "${DOCKER_DEV_ENVIRONMENT_HOME}" != "${PWD}" ]; then
  ENV_WARNING="Warning: there is no .env in your current working dir. Wrong pwd or missing project initialisation?"
fi

function parse_command_args() {

    if [ -v "PROJECT_ROOT" ]; then
        WORKINGDIRPART="-w /var/www/vhosts/${PROJECT_ROOT}"
    else
        WORKINGDIRPART=""
    fi

    if [ -v "args[--root]" ]; then
        USERPART="-u root"
    else
        USERPART="-u ${USER_ID}"
    fi

    if [ -v "args[--run]" ]; then
        MODEPART="run --rm"
    else
        MODEPART="exec"
    fi
}


