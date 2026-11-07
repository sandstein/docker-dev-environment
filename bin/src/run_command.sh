parse_exec_options "${other_args[@]}"
build_run_args
compose run --rm "${RUN_ARGS[@]}"
