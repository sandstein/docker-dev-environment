# Docker Development Environment

## Possible containers

Dockerfiles exist for the following

* php-fpm-57
* php-fpm-71
* php-fpm-72
* php-fpm-73
* php-fpm-74
* php-cli-57
* php-cli-71
* php-cli-72
* php-cli-73
* php-cli-74
* mysql-55
* mysql-56
* mysql-57
* mysql-80
* mariadb-55
* mariadb-100
* mariadb-101
* mariadb-102
* mariadb-103
* mariadb-104
* percona-57
* peronca-80
* apache-24
* solr-771
* tomcat-9
* redis-5
* mailhog
* varnish
* elastic-56
* elastic-64
* elastic-71
* elastic-73

Your local projects are mounted into the respective containers from the mount point
`/path/to/this/repo/vhosts`

So ideally you would symlink your projects directory to this location (`./vhosts`).

Apache vhosts are configured in the `.docker/apache/conf/vhosts` directory.
You can create a new `.conf` file per vhost. They are automatically loaded when starting/restarting your apache container.

If you do not use .localhost under linux, remember to edit your local hosts file when adding new vhosts.

## Initialisation and commands

There are some commands which - together with .env files will facilate your work. Copy `.env.sample` to `.env` and possibly
make changes according to your system.

Copy `.env.project-sample` to your projects root file (if not under version control) and edit settings therein.

The command `bin/dde-init` will set `DOCKER_DEV_ENVIRONMENT_HOME` in your .bashrc and add `${DOCKER_DEV_ENVIRONMENT_HOME}/bin`
to your `${PATH}`.

Then you can start all the needed containers by invoking
```bash
$ dde-start
```
in your project root dir, call
```bash
$ dde-cli [some-command]
```
to start a (php-)cli container and execute `[some-command]` inside the container. If you need to run some composer actions,
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


## Startup (old?)

`docker-compose up`

To individually rebuild a container, run

`docker-compose build containername`

To rebuild all containers, run

`docker-compose up --build`

To kill all containers, run

`docker-compose kill`

To SSH into a specific container, run

`docker exec -it containername /bin/bash`

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


