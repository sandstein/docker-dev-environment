parse_exec_options "${other_args[@]}"
build_run_args
compose exec "${RUN_ARGS[@]}"
