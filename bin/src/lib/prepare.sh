# Creates missing configuration files from their samples before a service
# starts, so the mounted files exist and belong to the user.
prepare_service() {
    local service="$1" config_file=""
    local config="${DDE_HOME}/config/${service}"

    case "${service}" in
        php-*) config_file="${config}/etc/php/php.ini" ;;
        mysql-*|percona-*|mariadb-*) config_file="${config}/etc/my.cnf" ;;
        ssh) config_file="${config}/tunnel.conf" ;;
        nginx-*) config_file="${config}/etc/nginx/conf.d/default.conf" ;;
        varnish-*) config_file="${config}/etc/varnish/default.vcl" ;;
    esac

    if [[ -z "${config_file}" || -f "${config_file}" ]]; then
        return 0
    fi

    case "${service}" in
        php-*)
            note "${service}: copying sample php.ini and conf.d/*.ini, adapt them to your needs"
            mkdir -p "${config}/etc/php/conf.d"
            cp "${config}/sample/conf.d/"*.ini "${config}/etc/php/conf.d/"
            cp "${config}/sample/php.ini.sample" "${config_file}"
            ;;
        nginx-*)
            note "${service}: copying sample default.conf, adapt it to your needs"
            cp "${config}/sample/conf.d/default.conf" "${config_file}"
            ;;
        varnish-*)
            note "${service}: copying sample default.vcl, adapt it to your needs"
            cp "${config}/sample/default.vcl" "${config_file}"
            ;;
        *)
            note "${service}: creating empty ${config_file}"
            mkdir -p "$(dirname "${config_file}")"
            touch "${config_file}"
            ;;
    esac
}
