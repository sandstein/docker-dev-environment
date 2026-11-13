service="$(resolve_service "${args[--service]:-}")" || exit 1
resolve_workdir_args "${service}" "${args[--workdir]:-}"
TERMINAL_ENV_ARGS=()
[[ -t 0 ]] && terminal_env_args
compose exec -u "${args[--user]:-${USER_ID}}" "${WORKDIR_ARGS[@]}" "${TERMINAL_ENV_ARGS[@]}" "${service}" \
    sh -c 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
