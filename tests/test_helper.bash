# shellcheck shell=bash
#
# Shared setup for the dde bats suite.
#
# Each test gets an isolated dde installation in $BATS_TEST_TMPDIR:
#
#   $DDE_HOME/bin/dde          copy of the generated script under test
#   $DDE_HOME/.env             fixture (tests/fixtures/env)
#   $DDE_HOME/vhosts        -> $WORKSPACE
#   $WORKSPACE/project         the current working directory of the test
#
# `docker` is replaced by tests/bin/docker, which records every call in
# $DDE_TEST_LOG instead of talking to a daemon.

DDE_REPO="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup_dde() {
    local tmp
    tmp="$(cd "${BATS_TEST_TMPDIR}" && pwd -P)"

    export HOME="${tmp}/home"
    export DDE_HOME="${tmp}/dde"
    export WORKSPACE="${tmp}/workspace"
    export PROJECT="${WORKSPACE}/project"
    export DDE_TEST_LOG="${tmp}/docker.log"
    export DDE_TEST_CONFIG_DIR="${DDE_REPO}/tests/fixtures/compose-config"

    mkdir -p "${HOME}" "${DDE_HOME}/bin" "${PROJECT}/sub/dir"
    cp "${DDE_REPO}/bin/dde" "${DDE_HOME}/bin/dde"
    cp "${DDE_REPO}/tests/fixtures/env" "${DDE_HOME}/.env"
    ln -s "${WORKSPACE}" "${DDE_HOME}/vhosts"
    : > "${DDE_TEST_LOG}"

    export DOCKER_DEV_ENVIRONMENT_HOME="${DDE_HOME}"
    export PATH="${DDE_REPO}/tests/bin:${DDE_HOME}/bin:${PATH}"
    export NO_COLOR=1
    unset DOCKER_CONTAINER DEFAULT_CONTAINER PHP_CLI_CONTAINER PHP_FPM_CONTAINER PROJECT_ROOT

    cd "${PROJECT}" || return 1
}

# Writes the given KEY=VALUE lines to the project's .env.dde
project_env() {
    printf '%s\n' "$@" > "${PROJECT}/.env.dde"
}

# Prefix every compose call starts with
compose_prefix() {
    printf 'compose -f %q' "${DDE_HOME}/docker-compose.yml"
}

# Prints all recorded docker calls
docker_calls() {
    cat "${DDE_TEST_LOG}"
}

# Fails unless the recorded docker calls equal the given lines exactly
assert_docker_calls() {
    local expected actual
    expected="$(printf '%s\n' "$@")"
    actual="$(docker_calls)"
    if [[ "${expected}" != "${actual}" ]]; then
        printf 'expected docker calls:\n%s\n\nactual docker calls:\n%s\n' "${expected}" "${actual}" >&2
        return 1
    fi
}

# Fails unless no docker call was recorded
assert_no_docker_calls() {
    if [[ -s "${DDE_TEST_LOG}" ]]; then
        printf 'expected no docker calls, got:\n%s\n' "$(docker_calls)" >&2
        return 1
    fi
}

# Fails unless $output contains the given string
assert_output_contains() {
    if [[ "${output}" != *"$1"* ]]; then
        printf 'expected output to contain:\n  %s\nactual output:\n%s\n' "$1" "${output}" >&2
        return 1
    fi
}

# Fails unless $output does not contain the given string
refute_output_contains() {
    if [[ "${output}" == *"$1"* ]]; then
        printf 'expected output not to contain:\n  %s\nactual output:\n%s\n' "$1" "${output}" >&2
        return 1
    fi
}

# Fails unless the last `run` exited with the given status
assert_status() {
    if [[ "${status}" -ne "$1" ]]; then
        printf 'expected status %s, got %s\noutput:\n%s\n' "$1" "${status}" "${output}" >&2
        return 1
    fi
}
