# Simple Docker deployment of the ACDH repository

## Running

**General remarks (apply to all setups):**

* If you are using docker on linux you might need to use `sudo docker (...)` instead of `docker` depending on your system configuration.
* Repository isn't ready just after the docker container start. You need to wait until it finishes the whole initialization process. At the first start it can take a few minutes. Please watch https://www.youtube.com/watch?v=MTCuBOcl64c to see how to check initialization progress.

### Quick & dirty 10-minutes deployment

```bash
docker run --name acdh-repo -p 80:80 -e CFG_BRANCH=arche -d acdhch/arche
```

You can also watch in at https://www.youtube.com/watch?v=MTCuBOcl64c.

### With data directories mounted in host

In this setup all the data are stored in a given host location which assures data persistency and gives you direct access to them.

It's probably the best choice if you want to run it locally on your computer/server or when you run it on a dedicated VM.

```bash
VOLUMES_DIR=absolute_path_on_your_computer_where_repo_data_are_to_be_stored
git clone https://github.com/acdh-oeaw/arche-docker-config.git -b arche $VOLUMES_DIR/config
for i in data tmp postgresql log vendor gui; do
    mkdir -p $VOLUMES_DIR/$i
done
docker run --name acdh-repo -p 80:80 -v $VOLUMES_DIR/data:/home/www-data/data -v $VOLUMES_DIR/tmp:/home/www-data/tmp -v $VOLUMES_DIR/postgresql:/home/www-data/postgresql -v $VOLUMES_DIR/log:/home/www-data/log -v $VOLUMES_DIR/vendor:/home/www-data/vendor -v $VOLUMES_DIR/config:/home/www-data/config -v $VOLUMES_DIR/gui:/home/www-data/gui -e USER_UID=`id -u` -e USER_GID=`id -g` -d acdhch/arche
```

### With data directories in Docker named volumes

In this setup all the data are stored in a Docker named volumes which assures data persistency between Docker container runs.

It doesn't allow you to inspect data directly on the host machine but integrates with Docker volumes which may be a selling point when you run it in a cloud environment (e.g. your cloud may provide such volume-features like automated backups, migration between VMs, high availbility, etc.).

It's probably the best choice for running in a container-as-service cloud (Portainer, Kubernetes, etc.).

```bash
for i in data tmp postgresql log vendor config gui; do
  docker volume create repo-$i
done
docker run --name acdh-repo -p 80:80i -e CFG_BRANCH=arche --mount source=repo-data,destination=/home/www-data/data --mount source=repo-tmp,destination=/home/www-data/tmp --mount source=repo-postgresql,destination=/home/www-data/postgresql --mount source=repo-log,destination=/home/www-data/log --mount source=repo-vendor,destination=/home/www-data/vendor --mount source=repo-config,destination=/home/www-data/config --mount source=repo-gui,destination=/home/www-data/gui -d acdhch/arche
```

## Adjusting the configuration

This image provides only a runtime environment. Configuration (repository config file, startup scripts, etc.) is assumed to be provided separately in the `/home/www-data/config` directory.

You can:

* Either explicitely provide the desired configuration by mounting it from host machine folder/docker volume (`-v /path/to/my/config:/home/www-data/config` or `--mount source=configVolumeName,destination=/home/www-data/config` parameter added to the `docker run` command). An example of such setup is the _with data directories mounted in host_ deployment above.
* Or instruct the image to fetch it from a given git repository by setting the `CFG_REPO` and optionally `CFG_BRANCH` (if not set, `master` is assumed) environment variable (`-e CFG_REPO=gitRepoUrl` and `-e CFG_BRANCH=branchName` parameters added to the `docker run` command). An example of such setup (using only `CFG_BRANCH` and keeping the default config repository) is the `Quick & dirty 10-minutes deployment` setup above.

By default (if you don't use any of above-mentioned options) the branch `master` of the https://github.com/acdh-oeaw/arche-docker-config.git repository is used.

Be aware that:

* The git repository is checked out only if the `/home/www-data/config` directory inside the container is empty.
* The repository is not automatically updated on the container run. This is because configuration updates may be dangerous and an update should be a conscious decision of a maintainer.

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
      {"Host":"shares/vendor", "Guest":"/home/www-data/vendor", "Rights":"rw"},
      {"Host":"shares/config", "Guest":"/home/www-data/config", "Rights":"rw"},
      {"Host":"shares/drupal", "Guest":"/home/www-data/gui", "Rights":"rw"}
    ]
  }
]
```
2. Prepare directories for persistent storage
```bash
mkdir -p shares/data shares/tmp shares/postgresql shares/log shares/vendor shares/docker shares/config shares/drupal
```
3. Prepare the Dockerfile
```bash
echo -e "FROM acdhch/arche\nMAINTAINER Mateusz Żółtak <mzoltak@oeaw.ac.at>" > shares/docker/Dockerfile
```
4. Download the configuration
```bash
git clone https://github.com/acdh-oeaw/arche-docker-config.git shares/config && cd shares/config && git checkout arche
```
5. Inspect and adjust the configuration (the must is to set the `urlBase` to `https://ServerNameYouSetInTheConfig.json` in the `config.yaml`, everything else is optional).
6. Run `docker-manage`

