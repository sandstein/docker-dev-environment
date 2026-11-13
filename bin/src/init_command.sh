write_dderc

managed=""
if [[ -n "${args[--no-rc]:-}" ]]; then
    note "left ~/.bashrc and ~/.zshrc unchanged (--no-rc)"
elif shell_has_dde; then
    managed=1
    note "your shell already sets up dde (DOCKER_DEV_ENVIRONMENT_HOME and PATH), left ~/.bashrc and ~/.zshrc unchanged"
else
    hooked=""
    for rc_file in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
        hook_rc_file "${rc_file}" && hooked=1
    done
    [[ -n "${hooked}" ]] || warn "neither ~/.bashrc nor ~/.zshrc exists, add 'source ~/.docker/.dderc' to your shell's rc file"
fi

if [[ ! -f "${DDE_HOME}/.env" ]]; then
    warn "${DDE_HOME}/.env is missing: copy .env.sample to .env and adapt it"
fi
if [[ ! -e "${DDE_HOME}/vhosts" ]]; then
    warn "${DDE_HOME}/vhosts is missing: symlink it to the directory containing your projects"
fi

if [[ -n "${managed}" ]]; then
    green "dde is set up by your shell, ~/.docker/.dderc is only a fallback"
else
    green "dde is set up in ~/.docker/.dderc. Open a new shell or run: source ~/.docker/.dderc"
fi
