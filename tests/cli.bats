#!/usr/bin/env bats
#
# Behaviour of the 0.x command line interface.

load test_helper

setup() {
    setup_dde
}

@test "dde --version prints the version" {
    run dde --version
    assert_status 0
    assert_output_contains "0.1.0"
}

@test "missing .env in the dde home aborts" {
    rm "${DDE_HOME}/.env"
    run dde list
    assert_status 1
    assert_output_contains "copy the file .env.sample"
    assert_no_docker_calls
}

@test "list prints all compose services" {
    run dde list
    assert_status 0
    assert_docker_calls "$(compose_prefix) config --services"
}

@test "start without arguments starts every container from DOCKER_CONTAINER" {
    project_env "DOCKER_CONTAINER=redis-7,apache-24"
    run dde start
    assert_status 0
    assert_docker_calls \
        "$(compose_prefix) up -d redis-7" \
        "$(compose_prefix) up -d apache-24"
}

@test "start -r stops before starting" {
    project_env "DOCKER_CONTAINER=redis-7"
    run dde start -r
    assert_status 0
    assert_docker_calls \
        "$(compose_prefix) stop redis-7" \
        "$(compose_prefix) up -d redis-7"
}

@test "start with an explicit comma separated list ignores DOCKER_CONTAINER" {
    project_env "DOCKER_CONTAINER=redis-7"
    run dde start apache-24,mailpit
    assert_status 0
    assert_docker_calls \
        "$(compose_prefix) up -d apache-24" \
        "$(compose_prefix) up -d mailpit"
}

@test "start appends the legacy PHP_FPM_CONTAINER" {
    project_env "DOCKER_CONTAINER=redis-7" "PHP_FPM_CONTAINER=redis-6"
    run dde start
    assert_status 0
    assert_docker_calls \
        "$(compose_prefix) up -d redis-7" \
        "$(compose_prefix) up -d redis-6"
}

@test "start without any container prints a warning" {
    run dde start
    assert_output_contains "No container given!"
    assert_no_docker_calls
}

@test "restart restarts the configured containers" {
    project_env "DOCKER_CONTAINER=redis-7"
    run dde restart
    assert_status 0
    assert_docker_calls \
        "$(compose_prefix) stop redis-7" \
        "$(compose_prefix) up -d redis-7"
}

@test "start copies php sample configuration on first start" {
    mkdir -p "${DDE_HOME}/config/php-cli-83/sample/conf.d" "${DDE_HOME}/config/php-cli-83/etc/php/conf.d"
    echo "memory_limit=1G" > "${DDE_HOME}/config/php-cli-83/sample/php.ini.sample"
    echo "xdebug.mode=off" > "${DDE_HOME}/config/php-cli-83/sample/conf.d/xdebug.ini"
    run dde start php-cli-83
    assert_status 0
    [[ "$(cat "${DDE_HOME}/config/php-cli-83/etc/php/php.ini")" == "memory_limit=1G" ]]
    [[ -f "${DDE_HOME}/config/php-cli-83/etc/php/conf.d/xdebug.ini" ]]
}

@test "start keeps an existing php.ini" {
    mkdir -p "${DDE_HOME}/config/php-cli-83/sample/conf.d" "${DDE_HOME}/config/php-cli-83/etc/php/conf.d"
    echo "sample" > "${DDE_HOME}/config/php-cli-83/sample/php.ini.sample"
    echo "mine" > "${DDE_HOME}/config/php-cli-83/etc/php/php.ini"
    run dde start php-cli-83
    assert_status 0
    [[ "$(cat "${DDE_HOME}/config/php-cli-83/etc/php/php.ini")" == "mine" ]]
}

@test "start touches a missing my.cnf for database containers" {
    mkdir -p "${DDE_HOME}/config/mysql-80/etc"
    run dde start mysql-80
    assert_status 0
    [[ -f "${DDE_HOME}/config/mysql-80/etc/my.cnf" ]]
}

@test "command runs in the default container and the project directory" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde command "ls -l"
    assert_status 0
    assert_docker_calls "$(compose_prefix) exec -u 1234 -w /var/www/vhosts/project php-cli-83 ls -l"
}

@test "command maps a sub directory of the project" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    cp .env.dde sub/dir/.env.dde
    cd sub/dir
    run dde command "pwd"
    assert_status 0
    assert_docker_calls "$(compose_prefix) exec -u 1234 -w /var/www/vhosts/project/sub/dir php-cli-83 pwd"
}

@test "command honours PROJECT_ROOT" {
    project_env "DEFAULT_CONTAINER=php-cli-83" "PROJECT_ROOT=other/root"
    run dde command "pwd"
    assert_status 0
    assert_docker_calls "$(compose_prefix) exec -u 1234 -w /var/www/vhosts/other/root php-cli-83 pwd"
}

@test "command prefers the legacy PHP_CLI_CONTAINER over DEFAULT_CONTAINER" {
    project_env "DEFAULT_CONTAINER=php-cli-83" "PHP_CLI_CONTAINER=php-cli-74"
    run dde command "pwd"
    assert_docker_calls "$(compose_prefix) exec -u 1234 -w /var/www/vhosts/project php-cli-74 pwd"
}

@test "command flags: service, root, no tty, working dir" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde command -T -o -s redis-7 -w /data "redis-cli flushall"
    assert_status 0
    assert_docker_calls "$(compose_prefix) exec -T -u root -w /data redis-7 redis-cli flushall"
}

@test "command -d drops the working dir" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde command -d -s mysql-80 "mysql --version"
    assert_status 0
    assert_docker_calls "$(compose_prefix) exec -u 1234 mysql-80 mysql --version"
}

@test "command -r uses docker compose run" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde command -r "php -v"
    assert_status 0
    assert_docker_calls "$(compose_prefix) run --rm -u 1234 -w /var/www/vhosts/project php-cli-83 php -v"
}

@test "command without a service prints a warning" {
    run dde command "ls"
    assert_output_contains "Could not determine the service"
    assert_no_docker_calls
}

@test "command keeps quoted arguments together" {
    skip "known 0.x bug: the command string is split on spaces (fixed in 1.0 by dde exec)"
    project_env "DEFAULT_CONTAINER=mysql-80"
    run dde command "mysql -e 'SELECT 1'"
    assert_docker_calls "$(compose_prefix) exec -u 1234 -w /var/www/vhosts/project mysql-80 mysql -e SELECT\\ 1"
}

@test "bash opens a shell in the default container" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde bash
    assert_status 0
    assert_docker_calls "$(compose_prefix) exec -u 1234 -w /var/www/vhosts/project php-cli-83 bash"
}

@test "bash -o -s opens a root shell in another container" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde bash -o -s apache-24
    assert_status 0
    assert_docker_calls "$(compose_prefix) exec -u root -w /var/www/vhosts/project apache-24 bash"
}

@test "build rebuilds the configured containers without cache" {
    project_env "DOCKER_CONTAINER=redis-7,apache-24"
    run dde build
    assert_status 0
    assert_docker_calls \
        "$(compose_prefix) build --force-rm --pull --no-cache redis-7" \
        "$(compose_prefix) build --force-rm --pull --no-cache apache-24"
}

@test "build refuses --all together with --restart" {
    run dde build --all --restart
    assert_output_contains "can not provide the two options together"
    assert_no_docker_calls
}

@test "init writes ~/.docker/.dderc and hooks it into .bashrc" {
    touch "${HOME}/.bashrc"
    unset DOCKER_DEV_ENVIRONMENT_HOME
    run dde init
    assert_status 0
    grep -q "source ~/.docker/.dderc" "${HOME}/.bashrc"
    grep -q "export DOCKER_DEV_ENVIRONMENT_HOME=\"${DDE_HOME}\"" "${HOME}/.docker/.dderc"
}

@test "init references the completions inside the dde home" {
    skip "known 0.x bug: the completions path is expanded while writing .dderc (fixed in 1.0)"
    touch "${HOME}/.bashrc"
    unset DOCKER_DEV_ENVIRONMENT_HOME
    run dde init
    grep -q "\${DOCKER_DEV_ENVIRONMENT_HOME}/bin/completions.bash" "${HOME}/.docker/.dderc"
}
