# Runs after the arguments were parsed, before the command: loads the dde wide
# settings (.env in the dde home) and the project settings (.env.dde,
# searched upwards from $PWD). `dde init` works without them.

if [[ "${action}" != "init" ]]; then
    load_settings
fi
