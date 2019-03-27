# Docker Development Environment

Containers:

* php-fpm-57
* php-fpm-71
* php-fpm-72
* php-fpm-73
* php-fpm-57-xdebug
* php-fpm-71-xdebug
* php-fpm-72-xdebug
* php-fpm-73-xdebug
* mysql-57
* mysql-80
* apache

Your local projects are mounted into the respective containers from the mount point
`/path/to/this/repo/vhosts`

So ideally you would symlink your projects directory to this location (`./vhosts`).

Apache vhosts are configured in the `.docker/apache/conf/vhosts` directory.
You can create a new `.conf` file per vhost. They are automatically loaded when starting/restarting your apache container.

If you do not use .localhost under linux, remember to edit your local hosts file when adding new vhosts.

## Startup

`docker-compose up`

To individually rebuild a container, run

`docker-compose build containername`

To rebuild all containers, run

`docker-compose up --build`
:
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

If you need to debug your container, you can switch to xdebug by adding `XDEBUG` to the `Use` statement, e.g.: 
```
<VirtualHost "*:${HTTP_PORT}">
    ServerName example.localhost
    DocumentRoot "${VHOSTROOT}/example-project"
    Use PHP73XDEBUG "${VHOSTROOT}/example-project"
</VirtualHost>
```
Be careful to have at least one line break after the last `</VirtualHost>` statement.

## Using xdebug under PHPStorm

Just add a run configuration using your `example.localhost` adding a path matching


