write_dderc
hooked=""
for rc_file in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    hook_rc_file "${rc_file}" && hooked=1
done
[[ -n "${hooked}" ]] || warn "neither ~/.bashrc nor ~/.zshrc exists, add 'source ~/.docker/.dderc' to your shell's rc file"

if [[ ! -f "${DDE_HOME}/.env" ]]; then
    warn "${DDE_HOME}/.env is missing: copy .env.sample to .env and adapt it"
fi
if [[ ! -e "${DDE_HOME}/vhosts" ]]; then
    warn "${DDE_HOME}/vhosts is missing: symlink it to the directory containing your projects"
fi

green "dde is set up in ~/.docker/.dderc. Open a new shell or run: source ~/.docker/.dderc"
