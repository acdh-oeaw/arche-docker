# Simple Docker deployment of the ACDH repository

## Running

### Quick & dirty

```bash
docker run --name acdh-repo -p 80:80 -d zozlak/arche
```

#### With ARCHE doorkeeper, ontology, etc.

```bash
docker run --name acdh-repo -p 80:80 -e CFG_BRANCH=arche -d zozlak/arche
```

### With data directories mounted in host

In this setup all the data are stored in a given host location which assures data persistency and gives you direct access to them.

It's probably the best choice if you want to run it locally on your computer/server or when you run it on a dedicated VM.

```bash
VOLUMES_DIR=/absolute/path/to/data/location
for i in data tmp postgresql log vendor config; do
    mkdir -p $VOLUMES_DIR/$i
done
git clone https://github.com/acdh-oeaw/arche-docker-config.git $VOLUMES_DIR/config
docker run --name acdh-repo -p 80:80 -v $VOLUMES_DIR/data:/home/www-data/data -v $VOLUMES_DIR/tmp:/home/www-data/tmp -v $VOLUMES_DIR/postgresql:/home/www-data/postgresql -v $VOLUMES_DIR/log:/home/www-data/log -v $VOLUMES_DIR/vendor:/home/www-data/docroot/vendor -v $VOLUMES_DIR/config:/home/www-data/config -e USER_UID=`id -u` -e USER_GID=`id -g` -d zozlak/arche
```

### With data directories in Docker named volumes

In this setup all the data are stored in a Docker named volumes which assures data persistency between Docker container runs.

It doesn't allow you to inspect data directly on the host machine but integrates with Docker volumes which may be a selling point when you run it in a cloud environment (e.g. your cloud may provide such volume-features like automated backups, migration between VMs, high availbility, etc.).

It's probably the best choice for running in a container-as-service cloud (Portainer, Kubernetes, etc.).

```bash
for i in data tmp postgresql log vendor config; do
  docker volume create repo-$i
done
docker run --name acdh-repo -p 80:80 --mount source=repo-data,destination=/home/www-data/data --mount source=repo-tmp,destination=/home/www-data/tmp --mount source=repo-postgresql,destination=/home/www-data/postgresql --mount source=repo-log,destination=/home/www-data/log --mount source=repo-vendor,destination=/home/www-data/docroot/vendor --mount source=repo-config,destination=/home/www-data/config -d zozlak/arche
```

## Adjusting the configuration

This image provides only a runtime environment. Configuration (repository config file, startup scripts, etc.) is assumed to be provided separately in the `/home/www-data/config` directory.

You can:

* either explicitely provide the desired configuration by mounting it from host machine folder/docker volume (`-v /path/to/my/config:/home/www-data/config` or `--mount source=configVolumeName,destination=/home/www-data/config` parameter added to the `docker run` command) 
* or instruct the image to fetch it from a given git repository by setting the `CFG_REPO` and optionally `CFG_BRANCH` (if not set, `master` is assumed) environment variable (`-e CFG_REPO=gitRepoUrl` and `-e CFG_BRANCH=branchName` parameters added to the `docker run` command).

By default (if you don't use any of above-mentioned options) the branch `master` of the https://github.com/acdh-oeaw/arche-docker-config.git repository is used.

Be aware that the git repository is checked out only if the `/home/www-data/config` directory inside the container is empty and is not automatically updated on the container run. As configuration updates may be dangerous they are not performed automatically.

### Developing your own configuration

The easiest way is to start by forking the https://github.com/acdh-oeaw/arche-docker-config repository. See the repository README for detailed instructions.

### Rationale

Separation of the runtime environment and the configuration makes it easier to manage both runtime environment updates and multiple configuration. This is because runtime environment updates are most of the time independent from particular configuration and can be simply pushed upstream while configuration is highly deployment-specific and changes in it shouldn't affect a common runtime environment.

## Deploying at ACDH

A sample deployment putting all the persistent storage into the `shares` directory.

1. Create the config.json
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
echo -e "FROM zozlak/arche\nMAINTAINER Mateusz Żółtak <mzoltak@oeaw.ac.at>" > shares/docker/Dockerfile
```
4. Download the configuration
```bash
git clone https://github.com/acdh-oeaw/arche-docker-config.git shares/config && cd shares/config && git checkout arche
```
5. Inspect and adjust the configuration (the must is to set the `urlBase` to `https://ServerNameYouSetInTheConfig.json` in the `config.yaml`, everything else is optional).
6. Run `docker-manage`

