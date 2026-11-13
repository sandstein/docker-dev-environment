resolve_services
for service in "${SERVICES[@]}"; do
    prepare_service "${service}"
done
up_args=(-d)
[[ -n "${args[--build]:-}" ]] && up_args+=(--build)
[[ -n "${args[--force-recreate]:-}" ]] && up_args+=(--force-recreate)
compose up "${up_args[@]}" "${SERVICES[@]}"
