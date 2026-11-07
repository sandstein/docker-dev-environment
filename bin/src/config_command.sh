service_line() {
    local name="$1" value="$2"
    printf '%-20s %s\n' "${name}" "${value:-(not set)}"
}
service_line "dde home" "${DDE_HOME}"
service_line "compose file" "${DDE_COMPOSE_FILE}"
service_line "compose command" "${DOCKER_COMPOSE_COMMAND}"
service_line "user" "${USER_ID:-}:${GROUP_ID:-}"
service_line "volume base path" "${DOCKER_VOLUME_BASE_PATH:-}"
service_line "vhosts" "$(realpath "${DDE_HOME}/vhosts" 2>/dev/null)"
service_line "project settings" "${DDE_PROJECT_ENV:-}"
service_line "DOCKER_CONTAINER" "${DOCKER_CONTAINER:-}"
service_line "DEFAULT_CONTAINER" "${DEFAULT_CONTAINER:-}"
service_line "PROJECT_ROOT" "${PROJECT_ROOT:-}"
service_line "container workdir" "$(container_workdir)"
if [[ -n "${DOCKER_DEV_ENVIRONMENT_HOME:-}" && "$(realpath "${DOCKER_DEV_ENVIRONMENT_HOME}")" != "${DDE_HOME}" ]]; then
    warn "DOCKER_DEV_ENVIRONMENT_HOME (${DOCKER_DEV_ENVIRONMENT_HOME}) differs from the dde home, run dde init"
fi
