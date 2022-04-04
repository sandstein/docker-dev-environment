# Docker Development Environment

## Possible containers

Following dockerfiles exist

<table style="width:100%">
    <tr>
        <th>Webserver</th>
        <th>PHP modules</th>
        <th>Database modules</th>
        <th>Additional services</th>
    </tr>
    <tr>
        <td>
            apache24
        </td>
        <td>
            php-fpm-57<br>
            php-fpm-71<br>
            php-fpm-72<br>
            php-fpm-73<br>
            php-fpm-74<br>
            php-fpm-80<br>
            php-fpm-81<br>
        </td>
        <td>
            mysql-55<br>
            mysql-56<br>
            mysql-57<br>
            mysql-80<br>
        </td>
        <td>
            solr-771<br>
            tomcat-9<br>
            redis-5<br>
            mailhog<br>
            varnish<br>
        </td>
    </tr>
    <tr>
        <td>
        </td>
        <td>
            php-cli-57<br>
            php-cli-71<br>
            php-cli-72<br>
            php-cli-73<br>
            php-cli-74<br>
            php-cli-80<br>
            php-cli-81<br>
        </td>
        <td>
            mariadb-55<br>
            mariadb-100<br>
            mariadb-101<br>
            mariadb-102<br>
            mariadb-103<br>
            mariadb-104<br>
        </td>
        <td>
            percona-57<br>
            peronca-80<br>
        </td>
    </tr>
    <tr>
        <td>
        </td>
        <td>
        </td>
        <td>
        </td>
        <td>
            elastic-56<br>
            elastic-64<br>
            elastic-71<br>
            elastic-73<br>
        </td>
</tr>
</table>


##Setup docker dev enviroment to use it with your project

###Apache vhost
Your local projects are mounted into the respective containers from the mount point
`/path/to/this/repo/vhosts`.
So ideally you would symlink your projects directory to this location (`./vhosts`).

<!-- hier habe ich ggf. nicht richtig den link gesetzt? -->
```bash
$ ln -s /path/to/this/repo/vhosts /var/www/vhosts
```
<!-- liegt nicht in .docker -->
Apache vhosts are configured in the `docker/apache-24/conf/` directory.
You can create a new `<vhost-name>.conf` file per vhost. They are automatically loaded when starting/restarting your apache container.
If you do not use "project-name __.localhost__" within linux, remember to edit your local hosts file when adding new vhosts.

Example file
```
<VirtualHost "*:${HTTP_PORT}">
    ServerName project-name.localhost
    DocumentRoot "${VHOSTROOT}/project-name"
    Use PHP73 "${VHOSTROOT}/project-name"
</VirtualHost>
```

## Set correct enviroment for both docker enviroment and your project

There are some commands which together with .env files will facilate your work. Copy `.env.docker-sample` to `.env` in your docker-dev-enviroment folder and possibly
make changes according to your system.


Copy `.env.project-sample` to `.env` in your projects root folder (if not under version control) and edit settings therein.

```bash
$ cp ~/workspace/docker/docker-dev-environment/.env.docker-sample ~/workspace/docker/docker-dev-environment/.env
```


## Initialisation and commands
List of all commands placed  `bin/` dde - < command >
<table style="width:100%">
    <tr>
        <th>CLI options</th>
        <th>Controllers</th>
        <th>Initialization</th>
        <th>Others</th>
    </tr>
    <tr>
        <td>
        dde-bash<br>
        dde-cli<br>
        <br>
        dde-cron<br>
        dde-cron-bash<br>
        dde-cron-root-bash<br>
        <br>
        dde-exec<br>
        dde-exec-bash<br>
        dde-exec-root-bash<br>
        </td>
        <td>
<!--
    Ich sehe hier die aehnlichkeit zu systemd daher dde-down zu dde-stop aendern oder hinzufuegen?
    Kann gerade nicht einschaetzen wie ihr zu Redundanz steht wenn beide das selbe machen sollten
-->
        dde-start<br>
        dde-down<br>
        dde-restart<br>
        dde-rebuild<br>
        <br>
        </td>
        <td>
        dde-init<br>
        dde-build<br>
        dde-buildall<br>
        dde-<br>
        </td>
        <td>
        dde-defines<br>
        dde-test<br>
        dde-composer<br>
        </td>
    </tr>
</table>


The command `bin/dde-init` will set `DOCKER_DEV_ENVIRONMENT_HOME` in your .bashrc and add `${DOCKER_DEV_ENVIRONMENT_HOME}/bin`
to your `${PATH}`.

```bash
$ bin/dde-init
```

Then you can start all the needed containers by invoking.

---


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


---

Finally, if all the work is done and you want to save resources, you can just use

```bash
$ dde-down
```
or
```bash
$ dde-stop
```
to stop all the containers.


---

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

### SSH Sock mounted as Directory

Since the ssh sock can not be mounted as plain file it is necessary to add your User ID (UID)

```shell script
SSH_AUTH_SOCK_BASE=/run/user/<UID>/keyring
```
to your `.env` file. If you are working as another user, please change accordingly.
