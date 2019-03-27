# Docker Development Environment

Containers:

* php-fpm-57
* php-fpm-71
* php-fpm-72
* php-fpm-73
* mysql-57
* mysql-80
* apache

Your local project are mounted into the respective containers from the mount point
`/path/to/this/repo/vhosts`

So ideally you would symlink your projects directory to this location (`./vhosts`).

Apache vhosts are configured in the `.docker/apache/conf/vhosts` directory.
You can create a new `.conf` file per vhost. They are automatically loaded when starting/restarting your apache container.

Remember to edit your local hosts file when adding new vhosts.

## Startup

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

For each php version there is a single macro ready to be used in your vhosts.

e.g.:
```
<VirtualHost "*:${HTTP_PORT}">
    ServerName example.localhost
    DocumentRoot "${VHOSTROOT}/example-project"
    USE PHP73 "${VHOSTROOT}/example-project"
</VirtualHost>
```

## Solr Cores

To configure your own solr cores you can symlink your core config directories to `./solr-771-data/your_core`.
On top of this symlink 