# Messages go to stderr so stdout stays usable in pipes.

warn() {
    yellow "Warning: $*" >&2
}

note() {
    cyan "$*" >&2
}

fail() {
    red "Error: $*" >&2
    exit 1
}
