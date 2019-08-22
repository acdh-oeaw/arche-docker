# Simple Docker deployment of the ACDH repository

## Running

### Quick & dirty

```bash
docker run --name acdh-repo -p 80:8080 -d zozlak/acdh-repo
```

### With data directories mounted in host

In this setup all the data are stored in a given host location and all the components are running under invoking user priviledges.

```bash
VOLUMES_DIR=/absolute/path/to/data/location
mkdir $VOLUMES_DIR/data $VOLUMES_DIR/tmp $VOLUMES_DIR/postgresql $VOLUMES_DIR/log $VOLUMES_DIR/vendor
docker run --name acdh-repo -p 80:8080 -v $VOLUMES_DIR/data:/home/www-data/data -v $VOLUMES_DIR/tmp:/home/www-data/tmp -v $VOLUMES_DIR/postgresql:/home/www-data/postgresql -v $VOLUMES_DIR/log:/home/www-data/log -v $VOLUMES_DIR/vendor:/home/www-data/acdh-repo/vendor -e USER_UID=`id -u` -e USER_GID=`id -g` -d zozlak/acdh-repo
```

### Adjusting the config.yaml

Just mount it as *a volume* by adding `-v /path/to/config.yaml:/home/www-data/config.yaml`

