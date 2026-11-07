if [[ -n "${args[--short]:-}" ]]; then
    echo "${version}"
    exit 0
fi
echo "dde ${version}"
echo "compose:  $(compose version --short 2>/dev/null || echo "not available")"
echo "home:     ${DDE_HOME}"
echo "platform: $(uname -s) $(uname -m)"
