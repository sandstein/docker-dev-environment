#!/usr/bin/env bats
#
# Behaviour of the dde 1.x command line interface.

load test_helper

setup() {
    setup_dde
}

config_call() {
    printf '%s config %s' "$(compose_prefix)" "$1"
}

# --- general -----------------------------------------------------------------

@test "--version and version --short print the version" {
    run dde --version
    assert_status 0
    [[ "${output}" == "1.0.0" ]]

    run dde version --short
    assert_status 0
    [[ "${output}" == "1.0.0" ]]
}

@test "version shows home and platform" {
    run dde version
    assert_status 0
    assert_output_contains "dde 1.0.0"
    assert_output_contains "home:     ${DDE_HOME}"
}

@test "missing .env in the dde home aborts with a hint" {
    rm "${DDE_HOME}/.env"
    run dde ls
    assert_status 1
    assert_output_contains ".env is missing"
    assert_no_docker_calls
}

@test "list prints only the commands" {
    run dde list
    assert_status 0
    assert_output_contains "exec "
    assert_output_contains "ps "
    refute_output_contains "Usage:"
    refute_output_contains "--help"
}

@test "old 0.x commands are gone" {
    for cmd in command bash test; do
        run dde "${cmd}"
        assert_status 1
    done
    assert_no_docker_calls
}

@test "legacy PHP_CLI_CONTAINER prints a warning" {
    project_env "DEFAULT_CONTAINER=php-cli-83" "PHP_CLI_CONTAINER=php-cli-74"
    run dde ls
    assert_output_contains "PHP_CLI_CONTAINER"
    assert_output_contains "no longer supported"
}

# --- settings ----------------------------------------------------------------

@test ".env.dde is found in a parent directory" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    cd sub/dir
    run dde exec pwd
    assert_status 0
    assert_docker_calls \
        "$(config_call php-cli-83)" \
        "$(compose_prefix) exec -T -u 1234 -w /var/www/vhosts/project/sub/dir php-cli-83 pwd"
}

@test "a project .env is not read any more" {
    printf 'DEFAULT_CONTAINER=php-cli-83\n' > .env
    run dde exec pwd
    assert_status 1
    assert_output_contains "DEFAULT_CONTAINER is not set"
}

@test "config shows the resolved settings" {
    project_env "DOCKER_CONTAINER=redis-7,apache-24" "DEFAULT_CONTAINER=php-cli-83"
    cd sub
    run dde config
    assert_status 0
    assert_output_contains "${PROJECT}/.env.dde"
    assert_output_contains "redis-7,apache-24"
    assert_output_contains "/var/www/vhosts/project/sub"
}

# --- up / stop / down / restart / build / logs ---------------------------------

@test "up starts every container from DOCKER_CONTAINER in one call" {
    project_env "DOCKER_CONTAINER=redis-7,apache-24"
    run dde up
    assert_status 0
    assert_docker_calls "$(compose_prefix) up -d redis-7 apache-24"
}

@test "start is an alias of up" {
    project_env "DOCKER_CONTAINER=redis-7"
    run dde start
    assert_status 0
    assert_docker_calls "$(compose_prefix) up -d redis-7"
}

@test "up accepts space and comma separated services and flags" {
    project_env "DOCKER_CONTAINER=redis-7"
    run dde up --build --force-recreate apache-24,mailpit redis-6
    assert_status 0
    assert_docker_calls "$(compose_prefix) up -d --build --force-recreate apache-24 mailpit redis-6"
}

@test "up without any service fails" {
    run dde up
    assert_status 1
    assert_output_contains "DOCKER_CONTAINER is not set"
    assert_no_docker_calls
}

@test "up copies php sample configuration on first start" {
    mkdir -p "${DDE_HOME}/config/php-cli-83/sample/conf.d"
    echo "memory_limit=1G" > "${DDE_HOME}/config/php-cli-83/sample/php.ini.sample"
    echo "xdebug.mode=off" > "${DDE_HOME}/config/php-cli-83/sample/conf.d/xdebug.ini"
    run dde up php-cli-83
    assert_status 0
    [[ "$(cat "${DDE_HOME}/config/php-cli-83/etc/php/php.ini")" == "memory_limit=1G" ]]
    [[ -f "${DDE_HOME}/config/php-cli-83/etc/php/conf.d/xdebug.ini" ]]
}

@test "up keeps an existing php.ini" {
    mkdir -p "${DDE_HOME}/config/php-cli-83/sample/conf.d" "${DDE_HOME}/config/php-cli-83/etc/php/conf.d"
    echo "sample" > "${DDE_HOME}/config/php-cli-83/sample/php.ini.sample"
    echo "mine" > "${DDE_HOME}/config/php-cli-83/etc/php/php.ini"
    run dde up php-cli-83
    assert_status 0
    [[ "$(cat "${DDE_HOME}/config/php-cli-83/etc/php/php.ini")" == "mine" ]]
}

@test "up creates a missing my.cnf for database containers" {
    run dde up mysql-80
    assert_status 0
    [[ -f "${DDE_HOME}/config/mysql-80/etc/my.cnf" ]]
}

@test "stop and restart act on the project's containers" {
    project_env "DOCKER_CONTAINER=redis-7,apache-24"
    run dde stop
    run dde restart apache-24
    assert_docker_calls \
        "$(compose_prefix) stop redis-7 apache-24" \
        "$(compose_prefix) restart apache-24"
}

@test "stop --all stops every dde container" {
    run dde stop --all
    assert_status 0
    assert_docker_calls "$(compose_prefix) stop"
}

@test "down removes only the project's containers and never volumes" {
    project_env "DOCKER_CONTAINER=redis-7,apache-24"
    run dde down
    run dde down --all
    assert_docker_calls \
        "$(compose_prefix) down redis-7 apache-24" \
        "$(compose_prefix) down"
    refute_output_contains "-v"
}

@test "build uses the cache unless asked otherwise" {
    project_env "DOCKER_CONTAINER=redis-7,apache-24"
    run dde build
    run dde build --pull --no-cache php-cli-83
    run dde build --all
    assert_docker_calls \
        "$(compose_prefix) build redis-7 apache-24" \
        "$(compose_prefix) build --no-cache --pull php-cli-83" \
        "$(compose_prefix) build"
}

@test "logs passes follow and tail" {
    project_env "DOCKER_CONTAINER=redis-7"
    run dde logs -f -n 50
    assert_status 0
    assert_docker_calls "$(compose_prefix) logs --follow --tail 50 redis-7"
}

# --- exec / run / shell --------------------------------------------------------

@test "exec runs in the default container and the project directory" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde exec ls -la
    assert_status 0
    assert_docker_calls \
        "$(config_call php-cli-83)" \
        "$(compose_prefix) exec -T -u 1234 -w /var/www/vhosts/project php-cli-83 ls -la"
}

@test "exec keeps quoted arguments and the command's own options" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde exec -s mysql-80 mysql -u root -e 'SELECT 1' --help
    assert_status 0
    assert_docker_calls \
        "$(config_call mysql-80)" \
        "$(compose_prefix) exec -T -u 1234 mysql-80 mysql -u root -e SELECT\\ 1 --help"
}

@test "exec omits the working dir for services without the projects mount" {
    project_env "DEFAULT_CONTAINER=mysql-80"
    run dde exec mysql --version
    assert_status 0
    assert_docker_calls \
        "$(config_call mysql-80)" \
        "$(compose_prefix) exec -T -u 1234 mysql-80 mysql --version"
}

@test "exec options: user, workdir, env, long forms and --" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde exec --service=apache-24 -u root -w /tmp -e A=1 --env=B=2 -- ls -l
    assert_status 0
    assert_docker_calls "$(compose_prefix) exec -T -u root -w /tmp -e A=1 -e B=2 apache-24 ls -l"
}

@test "exec honours PROJECT_ROOT" {
    project_env "DEFAULT_CONTAINER=php-cli-83" "PROJECT_ROOT=other/root"
    run dde exec pwd
    assert_status 0
    assert_docker_calls \
        "$(config_call php-cli-83)" \
        "$(compose_prefix) exec -T -u 1234 -w /var/www/vhosts/other/root php-cli-83 pwd"
}

@test "exec outside of vhosts uses the container's default working dir" {
    cd "${HOME}"
    run dde exec -s php-cli-83 pwd
    assert_status 0
    assert_output_contains "is not below"
    assert_docker_calls \
        "$(config_call php-cli-83)" \
        "$(compose_prefix) exec -T -u 1234 php-cli-83 pwd"
}

@test "exec rejects unknown dde options and missing values" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde exec -x ls
    assert_status 1
    assert_output_contains "unknown option -x"
    run dde exec -s
    assert_status 1
    assert_output_contains "needs a value"
    assert_no_docker_calls
}

@test "exec without a service fails" {
    run dde exec ls
    assert_status 1
    assert_output_contains "DEFAULT_CONTAINER is not set"
    assert_no_docker_calls
}

@test "run uses docker compose run --rm" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde run php -v
    assert_status 0
    assert_docker_calls \
        "$(config_call php-cli-83)" \
        "$(compose_prefix) run --rm -T -u 1234 -w /var/www/vhosts/project php-cli-83 php -v"
}

@test "shell opens bash (or sh) in the default container" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde shell
    assert_status 0
    assert_docker_calls \
        "$(config_call php-cli-83)" \
        "$(compose_prefix) exec -u 1234 -w /var/www/vhosts/project php-cli-83 sh -c if\\ command\\ -v\\ bash\\ \\>/dev/null\\ 2\\>\\&1\\;\\ then\\ exec\\ bash\\;\\ else\\ exec\\ sh\\;\\ fi"
}

@test "exec and shell pass the terminal type and locale only with a tty" {
    # needs util-linux script for a pseudo terminal; without one (the
    # non-tty case) no TERM is passed, as the tests above show
    script -qec true /dev/null > /dev/null 2>&1 || skip "util-linux script not available"
    project_env "DEFAULT_CONTAINER=mysql-80"
    env -u LC_ALL -u LC_CTYPE -u LC_MESSAGES TERM=xterm-256color COLORTERM=truecolor LANG=de_DE.UTF-8 \
        script -qec "dde exec mysql --version; dde shell" /dev/null > /dev/null
    [[ "$(docker_calls | grep -c -- "-e TERM=xterm-256color -e COLORTERM=truecolor -e LANG=de_DE.UTF-8 mysql-80")" -eq 2 ]]
}

@test "shell -s -u opens a root shell in another container" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde shell -s mysql-80 -u root
    assert_status 0
    [[ "$(docker_calls | tail -1)" == "$(compose_prefix) exec -u root mysql-80 sh -c "* ]]
}

@test "compose passes everything to docker compose" {
    run dde compose top php-cli-83 --help
    assert_status 0
    assert_docker_calls "$(compose_prefix) top php-cli-83 --help"
}

# --- listing -----------------------------------------------------------------

@test "ls and get services list sorted services, optionally filtered" {
    export DDE_TEST_SERVICES="php-cli-83 redis-7 php-cli-74 mysql-80 php-cli-84"
    run dde ls php-cli
    assert_status 0
    [[ "${output}" == $'php-cli-74\nphp-cli-83\nphp-cli-84' ]]

    run dde get services
    assert_status 0
    [[ "$(echo "${output}" | wc -l)" -eq 5 ]]
}

@test "ps and get containers show the project's containers and their state" {
    project_env "DOCKER_CONTAINER=redis-7,php-cli-83" "DEFAULT_CONTAINER=php-cli-83"
    export DDE_TEST_PS='redis-7\tUp 2 hours\nmysql-80\tExited (0)'
    run dde ps
    assert_status 0
    assert_output_contains "redis-7"
    assert_output_contains "Up 2 hours"
    [[ "$(echo "${output}" | grep php-cli-83)" == *"yes"*"not created"* ]]
    refute_output_contains "mysql-80"

    run dde get containers --all
    assert_status 0
    assert_output_contains "mysql-80"
    assert_output_contains "Exited (0)"
    refute_output_contains "php-cli-83"
}

# --- init --------------------------------------------------------------------

@test "init writes ~/.docker/.dderc and hooks it into bash and zsh once" {
    touch "${HOME}/.bashrc" "${HOME}/.zshrc"
    unset DOCKER_DEV_ENVIRONMENT_HOME
    run dde init
    assert_status 0
    run dde init
    [[ "$(grep -c "source ~/.docker/.dderc" "${HOME}/.bashrc")" -eq 1 ]]
    [[ "$(grep -c "source ~/.docker/.dderc" "${HOME}/.zshrc")" -eq 1 ]]
    grep -q "export DOCKER_DEV_ENVIRONMENT_HOME=\"${DDE_HOME}\"" "${HOME}/.docker/.dderc"
    grep -qF '"${DOCKER_DEV_ENVIRONMENT_HOME}/bin/completions.bash"' "${HOME}/.docker/.dderc"
}

@test "init leaves the rc files alone when the shell already sets up dde" {
    printf 'for f in ~/.config/shell/rc.d/*.sh; do . "$f"; done\n' > "${HOME}/.bashrc"
    cp "${HOME}/.bashrc" "${BATS_TEST_TMPDIR}/bashrc.orig"
    # setup_dde exports DOCKER_DEV_ENVIRONMENT_HOME=$DDE_HOME and puts its bin on the PATH
    run dde init
    assert_status 0
    assert_output_contains "already sets up dde"
    cmp "${HOME}/.bashrc" "${BATS_TEST_TMPDIR}/bashrc.orig"
    [[ -f "${HOME}/.docker/.dderc" ]]
}

@test "init hooks the rc files when the shell points to another dde" {
    touch "${HOME}/.bashrc"
    export DOCKER_DEV_ENVIRONMENT_HOME="${BATS_TEST_TMPDIR}"
    run dde init
    assert_status 0
    grep -qF "source ~/.docker/.dderc" "${HOME}/.bashrc"
}

@test "init --no-rc only writes ~/.docker/.dderc" {
    touch "${HOME}/.bashrc" "${HOME}/.zshrc"
    unset DOCKER_DEV_ENVIRONMENT_HOME
    run dde init --no-rc
    assert_status 0
    [[ ! -s "${HOME}/.bashrc" && ! -s "${HOME}/.zshrc" ]]
    [[ -f "${HOME}/.docker/.dderc" ]]
}

@test "init works without .env and the written rc file puts dde on the PATH" {
    rm "${DDE_HOME}/.env"
    touch "${HOME}/.bashrc"
    unset DOCKER_DEV_ENVIRONMENT_HOME
    run dde init
    assert_status 0
    assert_output_contains ".env is missing"
    run bash -c "PATH=/usr/bin:/bin; source '${HOME}/.docker/.dderc'; command -v dde"
    [[ "${output}" == "${DDE_HOME}/bin/dde" ]]
}
