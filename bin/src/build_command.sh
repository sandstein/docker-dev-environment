build_args=()
[[ -n "${args[--no-cache]:-}" ]] && build_args+=(--no-cache)
[[ -n "${args[--pull]:-}" ]] && build_args+=(--pull)
if [[ -n "${args[--all]:-}" ]]; then
    compose build "${build_args[@]}"
else
    resolve_services
    compose build "${build_args[@]}" "${SERVICES[@]}"
fi
