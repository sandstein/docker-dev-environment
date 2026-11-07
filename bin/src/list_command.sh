# the "Commands:" section of the generated usage
dde_usage | awk '/^Commands:/ { found = 1; next } found && /^$/ { exit } found { sub(/^  /, ""); print }'
