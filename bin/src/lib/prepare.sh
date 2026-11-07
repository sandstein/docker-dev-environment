# Runs before a service starts: creates its mount directories and missing
# configuration files from their samples, so the bind mounts exist and
# belong to the user (compose is told not to create them as root).

# Directory the compose files mount from (DOCKER_VOLUME_BASE_PATH).
volume_base() {
    printf '%s\n' "${DOCKER_VOLUME_BASE_PATH:-${DDE_HOME}}"
}

prepare_service() {
    local service="$1"
    create_mount_dirs "${service}"
    create_config "${service}"
}

# Creates the host directories listed for the service in services.tsv.
# Only possible when the docker daemon runs on this machine.
create_mount_dirs() {
    local service="$1" info dirs dir base
    info="$(service_info "${service}")" || return 0
    dirs="$(cut -f3 <<< "${info}")"
    [[ -n "${dirs}" ]] || return 0
    if [[ -n "${DOCKER_HOST:-}" && "${DOCKER_HOST}" != unix://* ]]; then
        return 0
    fi
    base="$(volume_base)"
    while IFS= read -r -d ':' dir; do
        if [[ ! -d "${base}/${dir}" ]]; then
            note "${service}: creating ${base}/${dir}"
            mkdir -p "${base}/${dir}" || fail "could not create ${base}/${dir}"
        fi
    done <<< "${dirs}:"
}

# Copies sample configuration into place on first start.
create_config() {
    local service="$1" config_file=""
    local sample="${DDE_HOME}/config/${service}"
    local config
    config="$(volume_base)/config/${service}"

    case "${service}" in
        php-*) config_file="${config}/etc/php/php.ini" ;;
        mysql-*|percona-*|mariadb-*) config_file="${config}/etc/my.cnf" ;;
        ssh) config_file="${config}/tunnel.conf" ;;
        nginx-*) config_file="${config}/etc/nginx/conf.d/default.conf" ;;
        varnish-*) config_file="${config}/etc/varnish/default.vcl" ;;
        opensearch-*) config_file="${config}/config/opensearch.yml" ;;
    esac

    if [[ -z "${config_file}" || -f "${config_file}" ]]; then
        return 0
    fi

    case "${service}" in
        php-*)
            note "${service}: copying sample php.ini and conf.d/*.ini, adapt them to your needs"
            mkdir -p "${config}/etc/php/conf.d"
            cp "${sample}/sample/conf.d/"*.ini "${config}/etc/php/conf.d/"
            cp "${sample}/sample/php.ini.sample" "${config_file}"
            ;;
        nginx-*)
            note "${service}: copying sample default.conf, adapt it to your needs"
            mkdir -p "$(dirname "${config_file}")"
            cp "${sample}/sample/conf.d/default.conf" "${config_file}"
            ;;
        varnish-*)
            note "${service}: copying sample default.vcl, adapt it to your needs"
            mkdir -p "$(dirname "${config_file}")"
            cp "${sample}/sample/default.vcl" "${config_file}"
            ;;
        opensearch-*)
            note "${service}: copying the sample configuration, adapt it to your needs"
            mkdir -p "${config}/config"
            cp -R "${sample}/sample/." "${config}/config/"
            ;;
        *)
            note "${service}: creating empty ${config_file}"
            mkdir -p "$(dirname "${config_file}")"
            touch "${config_file}"
            ;;
    esac
}
