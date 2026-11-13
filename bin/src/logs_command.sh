resolve_services
logs_args=()
[[ -n "${args[--follow]:-}" ]] && logs_args+=(--follow)
[[ -n "${args[--tail]:-}" ]] && logs_args+=(--tail "${args[--tail]}")
compose logs "${logs_args[@]}" "${SERVICES[@]}"
