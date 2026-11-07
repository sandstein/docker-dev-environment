#!/usr/bin/env bats
#
# dde and the generated compose/services.tsv

load test_helper

setup() {
    setup_dde
    mkdir -p "${DDE_HOME}/compose"
    printf '%s\t%s\t%s\n' \
        php-cli-83 1 "config/php-cli-83/etc/php:config/php-cli-83/composer" \
        mysql-80 0 "data/mysql-80:config/mysql-80/etc" \
        redis-7 0 "" \
        > "${DDE_HOME}/compose/services.tsv"
}

@test "exec takes the projects mount from services.tsv without asking compose" {
    project_env "DEFAULT_CONTAINER=php-cli-83"
    run dde exec pwd
    assert_status 0
    assert_docker_calls "$(compose_prefix) exec -T -u 1234 -w /var/www/vhosts/project php-cli-83 pwd"

    : > "${DDE_TEST_LOG}"
    run dde exec -s mysql-80 pwd
    assert_docker_calls "$(compose_prefix) exec -T -u 1234 mysql-80 pwd"
}

@test "services missing in services.tsv fall back to the compose config" {
    run dde exec -s apache-24 pwd
    assert_status 0
    assert_docker_calls \
        "$(compose_prefix) config apache-24" \
        "$(compose_prefix) exec -T -u 1234 -w /var/www/vhosts/project apache-24 pwd"
}

@test "up creates the mount directories below DOCKER_VOLUME_BASE_PATH as the user" {
    base="${BATS_TEST_TMPDIR}/volumes"
    echo "DOCKER_VOLUME_BASE_PATH=${base}" >> "${DDE_HOME}/.env"
    run dde up mysql-80 redis-7
    assert_status 0
    [[ -d "${base}/data/mysql-80" ]]
    [[ -d "${base}/config/mysql-80/etc" ]]
    [[ -f "${base}/config/mysql-80/etc/my.cnf" ]]
    [[ "$(stat -c %u "${base}/data/mysql-80" 2>/dev/null || stat -f %u "${base}/data/mysql-80")" == "$(id -u)" ]]
    assert_docker_calls "$(compose_prefix) up -d mysql-80 redis-7"
}

@test "up defaults the volume base to the dde home" {
    run dde up mysql-80
    assert_status 0
    [[ -d "${DDE_HOME}/data/mysql-80" ]]
}

@test "up does not create directories for a remote docker host" {
    export DOCKER_HOST=tcp://192.0.2.1:2376
    run dde up mysql-80
    assert_status 0
    [[ ! -d "${DDE_HOME}/data/mysql-80" ]]
}

@test "up seeds the opensearch configuration from its sample" {
    mkdir -p "${DDE_HOME}/config/opensearch-25/sample/opensearch-observability"
    echo "cluster.name: dde" > "${DDE_HOME}/config/opensearch-25/sample/opensearch.yml"
    echo "x" > "${DDE_HOME}/config/opensearch-25/sample/opensearch-observability/observability.yml"
    run dde up opensearch-25
    assert_status 0
    [[ "$(cat "${DDE_HOME}/config/opensearch-25/config/opensearch.yml")" == "cluster.name: dde" ]]
    [[ -f "${DDE_HOME}/config/opensearch-25/config/opensearch-observability/observability.yml" ]]
}

@test "migrate removes only the old bind volumes of the dde project" {
    export DDE_TEST_VOLUMES="dde_data_mysql_80 dde_vhosts dde_real_data"
    export DDE_TEST_VOLUME_INSPECT='dde_data_mysql_80 bind\ndde_vhosts bind\ndde_real_data '
    run dde migrate --yes
    assert_status 0
    assert_output_contains "removed 2 volumes"
    assert_docker_calls \
        "volume ls -q --filter label=com.docker.compose.project=dde" \
        "$(printf 'volume inspect --format %q dde_data_mysql_80 dde_vhosts dde_real_data' '{{.Name}} {{index .Options "o"}}')" \
        "volume rm dde_data_mysql_80" \
        "volume rm dde_vhosts"
}

@test "migrate asks before removing and aborts on no" {
    export DDE_TEST_VOLUMES="dde_vhosts"
    export DDE_TEST_VOLUME_INSPECT='dde_vhosts bind'
    run dde migrate <<< "n"
    assert_status 1
    assert_output_contains "aborted"
    refute_output_contains "volume rm"
    [[ "$(docker_calls)" != *"volume rm"* ]]
}

@test "migrate without legacy volumes does nothing" {
    run dde migrate
    assert_status 0
    assert_output_contains "nothing to migrate"
}
