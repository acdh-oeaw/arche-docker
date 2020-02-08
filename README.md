# Simple Docker deployment of the ACDH repository

## Running

### Quick & dirty

```bash
docker run --name acdh-repo -p 80:80 -d zozlak/acdh-repo
```

#### With ARCHE ontology and doorkeeper

Just use the docker image with tag `arche`:

```bash
docker run --name acdh-repo -p 80:80 -d zozlak/acdh-repo:arche
```

### With data directories mounted in host

In this setup all the data are stored in a given host location which assures data persistency and gives you direct access to them.

```bash
VOLUMES_DIR=/absolute/path/to/data/location
mkdir -p $VOLUMES_DIR/data $VOLUMES_DIR/tmp $VOLUMES_DIR/postgresql $VOLUMES_DIR/log $VOLUMES_DIR/vendor
docker run --name acdh-repo -p 80:80 -v $VOLUMES_DIR/data:/home/www-data/data -v $VOLUMES_DIR/tmp:/home/www-data/tmp -v $VOLUMES_DIR/postgresql:/home/www-data/postgresql -v $VOLUMES_DIR/log:/home/www-data/log -v $VOLUMES_DIR/vendor:/home/www-data/docroot/vendor -e USER_UID=`id -u` -e USER_GID=`id -g` -d zozlak/acdh-repo
```

### With data directories in Docker named volumes

In this setup all the data are stored in a Docker named volumes which assures data persistency between Docker container runs.

It doesn't allow you to inspect data directly on the host machine but integrates with Docker volumes which may be a selling point when you run it in a cloud environment (e.g. your cloud may provide such Docker volumes features like automated backups, migration between VMs, high availbility, etc.).

```bash
for i in data tmp postgresql log vendor config; do
  docker volume create repo-$i
done
docker run --name acdh-repo -p 80:80 --mount source=repo-data,destination=/home/www-data/data --mount source=repo-tmp,destination=/home/www-data/tmp --mount source=repo-postgresql,destination=/home/www-data/postgresql --mount source=repo-log,destination=/home/www-data/log --mount source=repo-vendor,destination=/home/www-data/docroot/vendor --mount source=repo-config,destination=/home/www-data/config -d zozlak/acdh-repo
```

### Adjusting the config.yaml and/or composer.json

Just mount them as *a volume* by adding `-v /path/to/config.yaml:/home/www-data/config/config.yaml` and/or `-v /path/to/composer.json:/home/www-data/config/composer.json` do the `docker run` command.

## Deploying at ACDH

A sample deployment putting all the persistent storage into the `shares` directory.

1. Create config.json
  (adjust `Name` and `ServerName`):
```json
[
  {
    "Type":"HTTP",
    "Name":"test",
    "DockerfileDir":"shares/docker",
    "ServerName":"test.localhost",
    "UserName":"www-data",
    "GroupName":"www-data",
    "Ports": {"Host":0, "Guest":80, "Type":"HTTP"},
    "Mounts": [
      {"Host":"shares/data", "Guest":"/home/www-data/data", "Rights":"rw"},
      {"Host":"shares/tmp", "Guest":"/home/www-data/tmp", "Rights":"rw"},
      {"Host":"shares/postgresql", "Guest":"/home/www-data/postgresql", "Rights":"rw"},
      {"Host":"shares/log", "Guest":"/home/www-data/log", "Rights":"rw"},
      {"Host":"shares/vendor", "Guest":"/home/www-data/docroot/vendor", "Rights":"rw"},
      {"Host":"shares/config", "Guest":"/home/www-data/config", "Rights":"rw"}
    ]
  }
]
```
2. Prepare directories for persistent storage
```bash
mkdir -p shares/data shares/tmp shares/postgresql shares/log shares/vendor shares/docker shares/config
```
3. Prepare the Dockerfile
```bash
echo -e "FROM zozlak/acdh-repo:arche\nMAINTAINER Mateusz Żółtak <mzoltak@oeaw.ac.at>" > shares/docker/Dockerfile
```

4. Download default `composer.json` and `config.yaml`
```bash
curl https://github.com/zozlak/acdh-repo-docker/raw/arche/root/home/www-data/config/composer.json > shares/config/composer.json
curl https://github.com/zozlak/acdh-repo-docker/raw/arche/root/home/www-data/config/config.yaml > shares/config/config.yaml
```

5. Inspect and adjust files downloaded in the previous point (especially set the `urlBase` to `https://ServerNameYouSetInTheConfig.json` in the `shares/config/config.yaml`).

6. Run `docker-manage`

