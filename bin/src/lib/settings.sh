# Loading of the dde wide (.env) and project (.env.dde) settings.

# Prints the path of the nearest .env.dde in $1 or one of its parents.
find_project_env() {
    local dir="$1"
    while [[ -n "${dir}" ]]; do
        if [[ -f "${dir}/.env.dde" ]]; then
            printf '%s\n' "${dir}/.env.dde"
            return 0
        fi
        [[ "${dir}" == "/" ]] && break
        dir="$(dirname "${dir}")"
    done
    return 0
}

load_settings() {
    # dde wide settings, see .env.sample
    if [[ ! -f "${DDE_HOME}/.env" ]]; then
        fail "${DDE_HOME}/.env is missing: copy ${DDE_HOME}/.env.sample to ${DDE_HOME}/.env and adapt it"
    fi
    set -a
    # shellcheck disable=SC1091
    . "${DDE_HOME}/.env"
    set +a
    DOCKER_COMPOSE_COMMAND="${DOCKER_COMPOSE_COMMAND:-docker compose}"

    # project settings, see .env.dde.sample
    DDE_PROJECT_ENV="$(find_project_env "${PWD}")"
    if [[ -n "${DDE_PROJECT_ENV}" ]]; then
        set -a
        # shellcheck disable=SC1090
        . "${DDE_PROJECT_ENV}"
        set +a
    fi

    local legacy
    for legacy in PHP_CLI_CONTAINER PHP_FPM_CONTAINER; do
        if [[ -n "${!legacy:-}" ]]; then
            warn "${legacy} in ${DDE_PROJECT_ENV} is no longer supported since dde 1.0, use DEFAULT_CONTAINER / DOCKER_CONTAINER"
        fi
    done
}
