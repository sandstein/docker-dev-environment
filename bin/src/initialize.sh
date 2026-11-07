# Runs before the arguments are parsed. Settings are loaded later in before.sh.

shopt -s extglob

SCRIPT_PATH="$(readlink -f "$0")"

# The dde home is the directory containing bin/dde (symlinks resolved).
DDE_HOME="$(dirname "$(dirname "${SCRIPT_PATH}")")"
DDE_COMPOSE_FILE="${DDE_HOME}/docker-compose.yml"
DDE_VHOSTS_TARGET="/var/www/vhosts"
