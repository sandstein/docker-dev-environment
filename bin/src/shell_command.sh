service="$(resolve_service "${args[--service]:-}")" || exit 1
resolve_workdir_args "${service}" "${args[--workdir]:-}"
compose exec -u "${args[--user]:-${USER_ID}}" "${WORKDIR_ARGS[@]}" "${service}" \
    sh -c 'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
