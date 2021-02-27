# Docker Development Environment

## Possible containers

Dockerfiles exist for the following.

### PHP
* php-fpm-57
* php-fpm-71
* php-fpm-72
* php-fpm-73
* php-fpm-74
* php-fpm-80
* php-cli-57
* php-cli-71
* php-cli-72
* php-cli-73
* php-cli-74
* php-cli-80

### Database

#### MariaDB
* mariadb-55
* mariadb-100
* mariadb-101
* mariadb-102
* mariadb-103
* mariadb-104

#### MySql
* mysql-55
* mysql-56
* mysql-57
* mysql-80

#### Percona
* percona-57
* peronca-80

### Webserver
* apache-24

### Other
* elastic-56
* elastic-64
* elastic-71
* elastic-73
* elastic-74
* elastic-76
* mailhog
* redis-5
* redis-6
* solr-771
* ssh
* tomcat-9
* varnish

## Initialisation and commands
__Note:__ to easily follow documentation clone the repo to `~/workspace/docker/dev-environment` and put your projects there.
```bash
$ cd ~/workspace/docker/dev-environment
```

Your local projects are mounted into the respective containers from the mount point
`/path/to/this/repo/vhosts`

So ideally you would symlink your projects directory to this location (`./vhosts`).
```bash
$ ln - s ../.. vhosts
```

Apache vhosts are configured in the `config/apache-24/conf.d` directory.
You can create a new `.conf` file per vhost. They are automatically loaded when starting/restarting your apache container.

If you do not use `.localhost` under linux, remember to edit your local hosts file when adding new vhosts.

### Docker Development Environment setup
```bash
$ git clone https://github.com/sandstein/docker-dev-environment.git .
```

There are some commands which - together with `.env` files will facilitate your work. Copy `.env.sample` to `.env` and possibly
make changes according to your system.
```bash
$ cp .env.sample .env
```

Copy `.env.project-sample` to your projects root file (if not under version control) and edit settings therein.
```bash
$ cp .env.project-sample ~/workspace/example/project/.env
```

The command `bin/dde-init` will set `DOCKER_DEV_ENVIRONMENT_HOME` in your `.bashrc` and add `${DOCKER_DEV_ENVIRONMENT_HOME}/bin`
to your `${PATH}`.
```bash
$ bin/dde-init
```

### Project setup
Switch to your project `~/workspace/example/project/`. Then you can start all the needed containers for by invoking
```bash
$ dde-start
```
In your project root dir, call
```bash
$ dde-cli [some-command]
```
to start a (php-)cli container and execute `[some-command]` inside the container. If you need to run some `composer` actions,
there ist the command
```bash
$ dde-composer [commands and flags]
```

To rebuild all containers use
```bash
$ dde-rebuild
```

If you need to restart a single or multiple containers (e.g. your apache configuration or php-fpm configuration has
changed) you can use
```bash
$ dde-restart [service or services]
```

Finally, if all the work is done and you want to save resources, you can just use

```bash
$ dde-down
```

to stop all the containers.

## Container communication

All containers communicate on a single network layer.
If you want to reach a container from another container, then the container name can be used as a host name.
Docker automatically resolves those (container) host names to the corresponding container ip.

## Apache Macros

For each php version there is a single macro ready to be used in your vhosts, e.g.:
```
<VirtualHost "*:80">
    ServerName example.localhost
    DocumentRoot "${WORKSPACE}/example/project"
    Use PHP73 "${WORKSPACE}/example/project"
</VirtualHost>
```

Be careful to have at least one line break after the last `</VirtualHost>` statement.

## Using xdebug under PHPStorm

To enable xdebug copy `config/php-(cli|fpm)-(number)/sample/php.ini.sample` to `config/php-(cli|fpm)-(number)/etc/php/php.ini`.

Then just add a run web page configuration using your `example.localhost` adding a path mapping, e.g.:

| File/Directory                       | Absolute path on the server    |
|--------------------------------------|--------------------------------|
| `/home/USER/workspace/your/project`  | `/var/www/vhosts/your/project` |

## Mailhog

Mailhog is available at `mailhog.localhost`. Use `mailhog` as host and `1025` as port for SMTP settings.

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

## Customize PHP Extension

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
phpcli@xxx:/project/path/$ curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/phpcli/bin --filename=composer
```
inside your container. It will be found before the composer instance installed while building the image.

## SSH Sock mounted as Directory

Since the ssh sock can not be mounted as plain file it is necessary to add

```shell script
SSH_AUTH_SOCK_BASE=/run/user/1001/keyring
```
to your `.env` file. If you are working as another user, please change accordingly.


