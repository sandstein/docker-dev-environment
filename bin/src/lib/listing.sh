# Output of dde ls / dde ps.

# Prints all services, optionally filtered by a substring.
list_services() {
    local filter="${1:-}"
    compose config --services | sort -V | grep -F -- "${filter}" || true
}

# Prints the project's containers (or all existing dde containers with
# $1 set) with their state.
list_containers() {
    local all="${1:-}" service state
    local -A states=()
    local -a services=()
    while IFS=$'\t' read -r service state; do
        [[ -n "${service}" ]] && states["${service}"]="${state}"
    done < <(compose ps -a --format '{{.Service}}\t{{.Status}}' 2>/dev/null)

    if [[ -n "${all}" ]]; then
        mapfile -t services < <(printf '%s\n' "${!states[@]}" | sort -V)
    else
        resolve_services
        services=("${SERVICES[@]}")
    fi

    printf '%-24s %-8s %s\n' SERVICE DEFAULT STATUS
    for service in "${services[@]}"; do
        [[ -n "${service}" ]] || continue
        printf '%-24s %-8s %s\n' "${service}" \
            "$([[ "${service}" == "${DEFAULT_CONTAINER:-}" ]] && echo yes)" \
            "${states[${service}]:-not created}"
    done
}
