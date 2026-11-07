# Docker Development Environment (dde)

## About

dde provides versioned service containers (PHP CLI/FPM, MySQL/MariaDB/Percona,
Apache/nginx, Varnish, Redis, RabbitMQ, Elasticsearch/OpenSearch, Solr, Node,
Mailpit, ...) from one shared compose file, and the `dde` command to start them
and to run commands in them for the project you are working on.

## Prerequisites

Docker with the compose plugin and bash 4.2 or newer. For now only Linux is
supported.

## Getting started

Clone the repository, copy `.env.sample` to `.env` and edit `.env` to your
needs. Make sure the directories referenced there exist:

```bash
CONFIG_BASE=~/.config
SSH_BASE=~/.ssh
COMPOSER_BASE=~/.composer
```

Symlink the directory containing your projects to `vhosts` inside the dde
directory, e.g.:

```bash
ln -s ~/workspace vhosts
```

Then hook dde into your shell (puts `dde` on the `PATH` and loads the
completions) and open a new shell:

```bash
bin/dde init
```

To use dde in a project, copy `.env.dde.sample` to the project root as
`.env.dde` and set

- `DOCKER_CONTAINER`: comma separated list of the services the project needs
  (see `dde ls`), e.g. `apache-24,mysql-80,php-fpm-83,php-cli-83`
- `DEFAULT_CONTAINER`: the service `dde exec` and `dde shell` use when no
  `-s` is given, e.g. `php-cli-83`

dde finds the `.env.dde` in the current directory or any parent directory.

```bash
dde up            # start the project's containers
dde ps            # show them
dde shell         # interactive shell in the default container
dde exec bin/magento cache:clean
dde down          # stop and remove them again (data is kept)
```

## Commands

Run `dde list` for an overview and `dde <command> --help` for details.

| Command | Purpose |
|---|---|
| `dde up [SERVICE...]` (alias `start`) | Create and start containers; `--build`, `--force-recreate` |
| `dde stop [SERVICE...]` | Stop containers; `--all` for every dde container |
| `dde down [SERVICE...]` | Stop and remove containers, never volumes; `--all` for every dde container |
| `dde restart [SERVICE...]` | Restart containers |
| `dde build [SERVICE...]` | Build images; `--all`, `--pull`, `--no-cache` |
| `dde exec [OPTIONS] COMMAND...` | Run a command in a running container |
| `dde run [OPTIONS] COMMAND...` | Run a command in a new container (`docker compose run --rm`) |
| `dde shell` | Interactive bash (or sh); `-s`, `-u`, `-w` |
| `dde logs [SERVICE...]` | Container output; `-f`, `-n LINES` |
| `dde ps` / `dde get containers` | The project's containers and their state; `--all` for every dde container |
| `dde ls [FILTER]` / `dde get services` | All services dde can start |
| `dde compose ARGS...` | Any `docker compose` command against the dde compose file |
| `dde config` | The resolved settings for the current directory |
| `dde version` | Version information; `--short` for scripts |
| `dde init` | Shell integration |

Without service arguments, `up`, `stop`, `down`, `restart`, `build` and `logs`
act on `DOCKER_CONTAINER`. Services can be given space or comma separated.

`dde exec` and `dde run` take docker style options **before** the command;
everything after the first non-option is passed on unchanged:

| Option | Default |
|---|---|
| `-s, --service SERVICE` | `DEFAULT_CONTAINER` |
| `-u, --user USER` | `USER_ID` from the dde `.env` |
| `-w, --workdir DIR` | the current directory, mapped below `/var/www/vhosts` (or `/var/www/vhosts/$PROJECT_ROOT`); left out for services that don't mount the projects, e.g. databases |
| `-e, --env KEY=VALUE` | |
| `-T, --no-tty` | automatic when stdin is not a terminal (pipes, cron) |

```bash
dde exec -s mysql-80 mysql -u root -e 'SHOW DATABASES'
cat script.php | dde exec php /dev/stdin
dde exec -u root apt-get update
```

Scripts can check the major version with `dde version --short`; dde 0.x
prints `0.1.0` for `dde --version`.

## Upgrading from 0.x to 1.0

dde 1.0 follows the docker command line. The old commands are gone:

| 0.x | 1.0 |
|---|---|
| `dde start [-r] a,b` | `dde up a b` / `dde up --force-recreate a b` |
| `dde restart` | `dde restart` (docker compose restart) |
| `dde command "cmd args"` / `dde c` | `dde exec cmd args` |
| `dde command -o ...` | `dde exec -u root ...` |
| `dde command -r ...` | `dde run ...` |
| `dde command -d -s mysql-80 ...` | `dde exec -s mysql-80 ...` (working dir handled automatically) |
| `dde command -w DIR ...` | `dde exec -w DIR ...` |
| `dde bash [-o] [-s S]` | `dde shell [-u root] [-s S]` |
| `dde list` | `dde ls` / `dde get services` (`dde list` now lists the commands) |
| `dde build` (always `--pull --no-cache`) | `dde build --pull --no-cache` |

Also changed:

- A project `.env` is no longer read, only `.env.dde`, which is now also
  found in parent directories.
- `PHP_CLI_CONTAINER` and `PHP_FPM_CONTAINER` are no longer supported, use
  `DEFAULT_CONTAINER` and `DOCKER_CONTAINER`.
- Run `dde init` again once: it rewrites `~/.docker/.dderc` (fixes loading
  the completions and adds zsh support).

## Contributing

`bin/dde` and `bin/completions.bash` are generated with
[bashly](https://bashly.dev) from `bin/src`. Don't edit them directly:

```bash
make generate   # regenerate after changing bin/src
make check      # what CI runs: generated files up to date, lint, compose check, tests
make help       # all targets
```

All tools run in pinned docker images. See `tests/` for the bats suite.

## Container communication

All containers communicate on a single network layer.
If you want to reach a container from another container, then the container name can be used as a host name.
Docker automatically resolves those (container) host names to the corresponding container ip.

## Apache Macros

For each php version there is a single macro ready to be used in your vhosts, e.g.:
```
<VirtualHost "*:${HTTP_PORT}">
    ServerName example.localhost
    DocumentRoot "${VHOSTROOT}/example-project"
    Use PHP73 "${VHOSTROOT}/example-project"
</VirtualHost>
```

Be careful to have at least one line break after the last `</VirtualHost>` statement.

## Using xdebug under PHPStorm

Just add a run configuration using your `example.localhost` adding a path matching

## Solr Cores

To configure your own solr cores you can symlink your core config directories to `./solr-771-data/your_core`.
On top of this symlink.


## Upgrading from Version <= 20.07.17

### Resetting Volumes, Images and Container

Since the way the local volumes are mounted changed dramatically between these versions, you have to remove the docker
volumes and rebuild all containers. Your local volumes are kept in this action:

```shell script
$ for container in `docker container ls | grep dev-environment | awk '{print $1}'`; do docker container rm -f $container; done
$ for image in `docker image ls | grep dev-environment | awk '{print $1}'`; do docker image rm $image; done
$ for volume in `docker volume ls | grep dev-environment | awk '{print $2}'`; do docker volume rm $volume; done
$ docker volume prune
```

### Custimize PHP Extension

The PHP extensions can now be activated or deactivated under `config/php-(cli|fpm)-(number)/etc/php/php.ini` and
`config/php-(cli|fpm)-(number)/etc/php/conf.d/*.ini`. Since these are copied from sample data the first time a container
is started, you may have to remove previously existing `config/php-(cli|fpm)-(number)/etc/php/php.ini` file.

### No more php-(cli|fpm)-(number)-x Containers / Images

Since the `config/php-(cli|fpm)-(number)/etc/php/conf.d/xdebug.ini` can now be edited, there is no need to povide
special debugging containers.
Also the PHP??X apache macros have been removed, you need to change these in your apache vhost conf files.

### Customizable bin commands in the PHP-CLI-Containers

The directory `/home/phpcli/bin` is now mouted to your `config/php-cli-(number)/bin` dir, so you can put custom commmands
there, this is specially handy if you want for instance composer to be selfupdateable: Just type

```shell script
phpcli@xxxxxxxxx:/project/path/$ curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/phpcli/bin --filename=composer
```
inside your container. It will be found before the composer instance installed while building the image.

### SSH Sock mounted as Directory

Since the ssh sock can not be mounted as plain file it is necessary to add

```shell script
SSH_AUTH_SOCK_BASE=/run/user/1000/keyring
```
to your `.env` file. If you are working as another user, please change accordingly.


## Solr
Link the cores from Projekt into /opt/solr/server/solr using
```
solr@63c943baa576:/opt/solr/server/solr$  ln -s /var/www/vhosts/project/conf/Solr/core .
```
Load cores from webfrontend.

To add additional libs copy them into `lib/solr/xx` where xx is your verison eg. 77 for 7.7

## Apache SSL

Generate CA in Apache-Container

```shell
www-data@cc59351899ea:/usr/local/apache2/conf/conf.d/ssl$ ca-gen -v -c DE -l Dresden -o SNM  -n local-ca.willi.snmlab.de -e ca@willi.snmlab.de key/ca.key crt/ca.crt
```

Any name and subject can be used, but has to be rembered

Now import `crt/ca.crt` into your browsers

Then generate Project files
```shell
www-data@cc59351899ea:/usr/local/apache2/conf/conf.d/ssl$ cert-gen -v -c DE -l Dresden -o SNM -n bmbb.localhost -e admin@bmbb.localhost -a '*.bmbb.localhost' key/ca.key crt/ca.crt key/bmbb.key csr/bmbb.csr crt/bmbb.crt
```

use anything for bbmb, in vhost conf add

```apacheconf
Use SSL ca bmbb
```
USE
