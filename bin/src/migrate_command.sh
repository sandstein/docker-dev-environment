project="$(basename "${DDE_HOME}" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"

mapfile -t volumes < <(docker volume ls -q --filter "label=com.docker.compose.project=${project}")
legacy=()
if (( ${#volumes[@]} )); then
    while read -r name option; do
        [[ "${option}" == "bind" ]] && legacy+=("${name}")
    done < <(docker volume inspect --format '{{.Name}} {{index .Options "o"}}' "${volumes[@]}")
fi

if (( ${#legacy[@]} == 0 )); then
    green "nothing to migrate: no dde 0.x bind volumes found"
    exit 0
fi

echo "dde 0.x bind volumes (the data they point to stays where it is):"
printf '  %s\n' "${legacy[@]}"

if [[ -z "${args[--yes]:-}" ]]; then
    read -r -p "Remove these ${#legacy[@]} volumes? [y/N] " answer
    [[ "${answer}" =~ ^[yY] ]] || { echo "aborted"; exit 1; }
fi

failed=0
for volume in "${legacy[@]}"; do
    docker volume rm "${volume}" >/dev/null || failed=1
done
if (( failed )); then
    warn "some volumes are still used by old containers: run 'dde down --all' and 'dde migrate' again"
    exit 1
fi
green "removed ${#legacy[@]} volumes"
