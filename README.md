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
needs. Make sure the directories referenced there exist, e.g.
`SSH_BASE=~/.ssh` (mounted into the php-cli containers).

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
| `dde migrate` | Remove the named volumes of dde 0.x (data is kept) |
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
- Containers mount `config/`, `data/`, `lib/` and `vhosts` directly (bind
  mounts) instead of through named volumes. Your data stays where it is; the
  next `dde up` recreates the containers with the new mounts. Afterwards
  `dde migrate` removes the old, now unused volumes (only their docker
  entries, never the directories they pointed to).
- Versions of a service family share one build context, e.g. `docker/php-fpm`
  for all `php-fpm-*`.
- The php-cli containers no longer mount your `~/.config` (`CONFIG_BASE`) and
  `~/.nvm` (`NVM_BASE`), php-cli-83 no longer mounts `config/php-cli-83/local`,
  and `docker/php-cli*/env/` is gone. Shell setup, nvm and tools now come from
  optional dotfiles and `DDE_CLI_TOOLS`, see "php-cli extras" below.
- `docker-compose.yml` and `compose/` are generated from `services.yml`, see
  below. Local changes there are overwritten by `make generate`.

### Switching an existing installation

Databases and search indexes do **not** need to be dumped or recreated. In
0.x the named volumes were only pointers (`driver_opts: o: bind`) to
`data/<service>` below `DOCKER_VOLUME_BASE_PATH`; 1.0 mounts exactly these
directories at the same container paths, with the same server versions. The
files are not touched, only the way they are mounted changes.

1. Keep `DOCKER_VOLUME_BASE_PATH` in `.env` unchanged and compare `.env` with
   `.env.sample` for new variables.
2. Check out the new version in the existing dde directory (same directory,
   so the compose project name `dev-environment` stays the same).
3. Run `bin/dde init` and open a new shell.
4. If you used `docker/php-cli-8x/env/` or the mounted `~/.config`/`~/.nvm`
   in the php-cli containers, set up the "php-cli extras" below instead.
5. `dde down --all` removes the old containers (data is kept).
6. `dde up` in your projects recreates the containers with the bind mounts.
   Existing images are reused; `dde build` is optional because the effective
   Dockerfiles did not change.
7. Check that your databases are there, then run `dde migrate` to remove the
   old volume entries.

To go back to 0.x, check out the old version and start the containers with
it: compose recreates the old volume entries, pointing at the same
directories. A dump before upgrading is still cheap insurance, but never
delete `data/` or run `git clean -x` in the dde directory.

## Services and compose files

All services are defined in `services.yml`. `make generate` renders it with
the templates in `templates/` into `docker-compose.yml` (which only includes
the files below `compose/`), one `compose/<family>.yml` per service family
and `compose/services.tsv`, which tells `dde` which services mount the
projects and which directories to create before a service starts.

- Every service is on the network `app-tier` and reachable under its name.
- Images are built from `docker/<family>/Dockerfile`, which takes the base
  image as build argument `BASE_IMAGE` (set per version in `services.yml`),
  plus `USER_ID`/`GROUP_ID` so files written in containers belong to you.
- Mounts are bind mounts below `DOCKER_VOLUME_BASE_PATH` with
  `create_host_path: false`: compose never creates a missing directory as
  root, `dde up` creates it as you.

To add a version of an existing family, copy an entry in `services.yml`
(adjust image tag and host ports, which must stay unique), add its sample
configuration below `config/<family>-<tag>/` if the family needs one, and
run `make generate && make check`.

## php-cli extras: tools and dotfiles

The php-cli containers 8.2 and newer can get tools and your dotfiles. All of
it is optional and set in the dde `.env`:

| Variable | Effect |
|---|---|
| `DDE_CLI_TOOLS` | Comma separated, built into the image: `nvm`, `claude`, `codex`, `junie`, `nanocoder`, `neovim`, `lazygit` |
| `DDE_CLI_NODE` | Node version nvm installs as default (`lts/*`); nanocoder needs 22 or newer |
| `DDE_DOTFILES_CORE`, `DDE_DOTFILES_LOCAL` | Git URLs of bare dotfiles repositories, checked out on the first start |
| `SECRETS_BASE` | Directory mounted read-only to `~/.secrets` (e.g. `~/.secrets`) |

- Tools: rebuild after a change, `dde build php-cli-83 && dde up --force-recreate php-cli-83`.
  claude, codex and junie come from their vendors' install scripts and are
  installed for the container user (same uid as you) in `~/.local`; a rebuild
  (`--no-cache`) installs current versions. neovim, lazygit and nvm are pinned
  in `docker/php-cli/Dockerfile`. nanocoder is installed with npm into nvm's
  default Node; after switching Node in a project run
  `npm install -g @nanocollective/nanocoder` again.
- Dotfiles: cloned with your ssh agent and `~/.ssh/config` into
  `~/.cfg-core` / `~/.cfg-local` (alias `config` / `config-local` if your
  dotfiles define them). Files below `.ssh` and `.secrets` come from the host
  and are skipped; files the image already has (`.bashrc`, `.profile`) are
  moved to `~/.dotfiles-backup`. Takes effect for new containers:
  `dde up --force-recreate php-cli-83`.
- `~/.config` is `config/<service>/home-config` (the base images declare it a
  volume) and survives recreating the container; the rest of the home
  directory, including agent logins, does not.

## Contributing

`bin/dde`, `bin/completions.bash`, `docker-compose.yml` and `compose/` are
generated. Don't edit them directly:

```bash
make generate   # regenerate after changing bin/src, services.yml or templates/
make check      # what CI runs: generated files up to date, lint, compose check, tests
make help       # all targets
```

The CLI is built with [bashly](https://bashly.dev) from `bin/src`, the compose
files with `tools/generate.py`. All tools run in pinned docker images. See
`tests/` for the bats suite (CLI) and the python unit tests (generator).

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
