parse_command_args
if [ -v CONTAINER_WARNING ]; then
    red "${CONTAINER_WARNING}"
    red "${ENV_WARNING}"
else
    dde start "${CONTAINER_LIST}" -r
fi
