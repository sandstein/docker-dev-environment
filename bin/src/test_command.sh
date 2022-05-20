inspect_args
if [ -v "args[--service]" ]; then
    red "${args[--service]}"
fi
green "done"
