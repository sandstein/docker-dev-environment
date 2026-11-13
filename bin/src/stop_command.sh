if [[ -n "${args[--all]:-}" ]]; then
    compose stop
else
    resolve_services
    compose stop "${SERVICES[@]}"
fi
