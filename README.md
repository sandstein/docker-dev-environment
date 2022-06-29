# Docker Development Environment

Refactored with bashly
init with

$ alias bashly='docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly'
$ bashly generate

## Possible containers

Dockerfiles exist for the following

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
            ssh (for automatic tunnels)<br>
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
            elastic-56<br>
            elastic-64<br>
            elastic-71<br>
            elastic-73<br>
            elastic-76<br>
            elastic-710<br>
            elastic-716<br>
            esadmin
        </td>
    </tr>
    <tr>
        <td>
        </td>
        <td>
        </td>
        <td>
            percona-57<br>
            peronca-80<br>
        </td>
        <td>
            <strong>Selenium</strong>:<br>
            chrome-standalone<br>
            edge-standalone<br>
            firefox-standalone<br>
            chrome<br>
            edge<br>
            firefox<br>
            selenium-hub<br>
            selenium-side-runner<br>
        </td>
</tr>
</table>

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

### SSH Sock mounted as Directory

Since the ssh sock can not be mounted as plain file it is necessary to add

```shell script
SSH_AUTH_SOCK_BASE=/run/user/1000/keyring
```
to your `.env` file. If you are working as another user, please change accordingly.


# Rewrite cli

## Some ideas on how to rewrite:

1. mv dde-defines to config/defines
2. mv dde-xxx to modules/xxx
3. create dde which behaves "normal"

## List of commands and what they should do

dde help: prints general usage
dde list: list commands
dde help <command>:

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
