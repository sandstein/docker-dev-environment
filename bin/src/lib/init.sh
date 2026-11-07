# Helpers for dde init.

# Writes ~/.docker/.dderc, which puts dde on the PATH and loads completions.
write_dderc() {
    mkdir -p "${HOME}/.docker"
    cat > "${HOME}/.docker/.dderc" <<EOL
# docker dev environment, written by dde init
export DOCKER_DEV_ENVIRONMENT_HOME="${DDE_HOME}"
case ":\${PATH}:" in
    *":\${DOCKER_DEV_ENVIRONMENT_HOME}/bin:"*) ;;
    *) PATH="\${DOCKER_DEV_ENVIRONMENT_HOME}/bin:\${PATH}" ;;
esac
if [ -n "\${ZSH_VERSION:-}" ]; then
    autoload -U +X bashcompinit && bashcompinit
fi
if [ -f "\${DOCKER_DEV_ENVIRONMENT_HOME}/bin/completions.bash" ]; then
    . "\${DOCKER_DEV_ENVIRONMENT_HOME}/bin/completions.bash"
fi
EOL
}

# Appends the source line for .dderc to the given rc file once.
hook_rc_file() {
    local rc_file="$1"
    [[ -f "${rc_file}" ]] || return 1
    if ! grep -qF ".docker/.dderc" "${rc_file}"; then
        printf '\n# docker dev environment\nsource ~/.docker/.dderc\n' >> "${rc_file}"
        note "added dde to ${rc_file}"
    fi
    return 0
}
