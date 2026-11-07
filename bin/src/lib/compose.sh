# Helpers around docker compose and the services of the current project.

# Runs docker compose against the dde compose file.
compose() {
    local -a cmd
    read -ra cmd <<< "${DOCKER_COMPOSE_COMMAND}"
    "${cmd[@]}" -f "${DDE_COMPOSE_FILE}" "$@"
}

# Fills the array SERVICES from the command's (repeatable) service
# argument, splitting on spaces and commas. Without it DOCKER_CONTAINER from
# .env.dde is used.
resolve_services() {
    local list
    local -a given=()
    # bashly stores repeatable arguments as a quoted, space separated string
    eval "given=(${args[service]:-})"
    if (( ${#given[@]} )); then
        list="${given[*]}"
    else
        list="${DOCKER_CONTAINER:-}"
    fi
    read -ra SERVICES <<< "${list//,/ }"
    if (( ${#SERVICES[@]} == 0 )); then
        fail "no service given and DOCKER_CONTAINER is not set$(project_hint)"
    fi
}

# Prints the service given explicitly ($1) or DEFAULT_CONTAINER.
resolve_service() {
    if [[ -n "${1:-}" ]]; then
        printf '%s\n' "$1"
    elif [[ -n "${DEFAULT_CONTAINER:-}" ]]; then
        printf '%s\n' "${DEFAULT_CONTAINER}"
    else
        fail "no service given (-s) and DEFAULT_CONTAINER is not set$(project_hint)"
    fi
}

project_hint() {
    if [[ -z "${DDE_PROJECT_ENV:-}" ]]; then
        printf ' (no .env.dde found in %s or its parents)' "${PWD}"
    else
        printf ' (in %s)' "${DDE_PROJECT_ENV}"
    fi
}

# Succeeds if the service mounts the projects directory (vhosts).
service_mounts_vhosts() {
    compose config "$1" 2>/dev/null | grep -q "target: ${DDE_VHOSTS_TARGET}\$"
}

# Prints the container path of the current directory, or nothing if it is
# not below the dde vhosts directory.
container_workdir() {
    if [[ -n "${PROJECT_ROOT:-}" ]]; then
        printf '%s/%s\n' "${DDE_VHOSTS_TARGET}" "${PROJECT_ROOT}"
        return
    fi
    local vhosts pwd_real
    vhosts="$(realpath "${DDE_HOME}/vhosts" 2>/dev/null)" || return 0
    pwd_real="$(realpath "${PWD}")"
    if [[ "${pwd_real}" == "${vhosts}" ]]; then
        printf '%s\n' "${DDE_VHOSTS_TARGET}"
    elif [[ "${pwd_real}" == "${vhosts}/"* ]]; then
        printf '%s/%s\n' "${DDE_VHOSTS_TARGET}" "${pwd_real#"${vhosts}/"}"
    fi
}

# Fills the array WORKDIR_ARGS for running in service $1. An explicit
# directory ($2) wins; services without the projects mount get none.
resolve_workdir_args() {
    local service="$1" explicit="${2:-}" dir
    WORKDIR_ARGS=()
    if [[ -n "${explicit}" ]]; then
        WORKDIR_ARGS=(-w "${explicit}")
        return
    fi
    service_mounts_vhosts "${service}" || return 0
    dir="$(container_workdir)"
    if [[ -n "${dir}" ]]; then
        WORKDIR_ARGS=(-w "${dir}")
    else
        note "${PWD} is not below ${DDE_HOME}/vhosts, using the container's default working directory"
    fi
}

# Parses docker style options of dde exec / dde run. Everything from the
# first non-option on is the command.
#   EXEC_SERVICE, EXEC_USER, EXEC_WORKDIR, EXEC_TTY (0/1), EXEC_ENV (array),
#   EXEC_COMMAND (array)
parse_exec_options() {
    EXEC_SERVICE=""
    EXEC_USER=""
    EXEC_WORKDIR=""
    EXEC_TTY=1
    EXEC_ENV=()
    EXEC_COMMAND=()
    while (( $# )); do
        case "$1" in
            -s|--service|-u|--user|-w|--workdir|-e|--env)
                (( $# >= 2 )) || fail "option $1 needs a value"
                case "$1" in
                    -s|--service) EXEC_SERVICE="$2" ;;
                    -u|--user) EXEC_USER="$2" ;;
                    -w|--workdir) EXEC_WORKDIR="$2" ;;
                    -e|--env) EXEC_ENV+=(-e "$2") ;;
                esac
                shift 2
                ;;
            --service=*) EXEC_SERVICE="${1#*=}"; shift ;;
            --user=*) EXEC_USER="${1#*=}"; shift ;;
            --workdir=*) EXEC_WORKDIR="${1#*=}"; shift ;;
            --env=*) EXEC_ENV+=(-e "${1#*=}"); shift ;;
            -T|--no-tty) EXEC_TTY=0; shift ;;
            --) shift; break ;;
            -*) fail "unknown option $1 (dde options must come before the command)" ;;
            *) break ;;
        esac
    done
    EXEC_COMMAND=("$@")
    (( ${#EXEC_COMMAND[@]} )) || fail "no command given"
}

# Builds the common docker compose exec/run arguments into RUN_ARGS and
# prints nothing. Uses the EXEC_* variables from parse_exec_options.
build_run_args() {
    local service
    service="$(resolve_service "${EXEC_SERVICE}")" || exit 1
    resolve_workdir_args "${service}" "${EXEC_WORKDIR}"
    RUN_ARGS=()
    if (( EXEC_TTY == 0 )) || [[ ! -t 0 ]]; then
        RUN_ARGS+=(-T)
    fi
    RUN_ARGS+=(-u "${EXEC_USER:-${USER_ID}}")
    RUN_ARGS+=("${WORKDIR_ARGS[@]}" "${EXEC_ENV[@]}" "${service}" "${EXEC_COMMAND[@]}")
}
