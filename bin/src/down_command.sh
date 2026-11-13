# never pass -v: dde down must not remove any data
if [[ -n "${args[--all]:-}" ]]; then
    compose down
else
    resolve_services
    compose down "${SERVICES[@]}"
fi
