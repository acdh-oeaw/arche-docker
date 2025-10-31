# Dedicated VM setup

## System setup

### Making things work behind the proxy

* git
  ```
  git config --global http.proxy http://fifi.arz.oeaw.ac.at:8080/
  ```
* docker
  ```
  mkdir /etc/systemd/system/docker.service.d
  cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOL
  [Service]
  Environment="HTTP_PROXY=http://fifi.arz.oeaw.ac.at:8080/"
  Environment="HTTPS_PROXY=http://fifi.arz.oeaw.ac.at:8080/"
  Environment="NO_PROXY=127.0.0.1,localhost,10.3.6.33"
  EOL
  systemctl daemon-reload
  systemctl restart docker
  ```

### Icinga

* On hermes
  ```bash
  cat > /etc/icinga2/conf.d/arche-tmp.arz.oeaw.ac.at.conf << EOF
  object Host "arche-tmp.arz.oeaw.ac.at" {
        import "generic-host"
        address = "10.3.6.35"
        vars.os = "Linux"
        vars.osType = "Debian"
  }
  ```
  and adjust serice assign rules in the /etc/icinga2/conf.d/services.conf`
* On the VM
  ```bash
  adduser nagios
  mkdir /home/nagios/.ssh
  echo > /home/nagios/.ssh/authorized_keys <<EOF
  {public key from /home/icinga2/.ssh/id_ed25519.pub on hermes}
  EOF
  chmod 600 /home/nagios/.ssh/authorized_keys
  chmod 700 /home/nagios/.ssh
  chown -R nagios:nagios /home/nagios/.ssh/
  apt install -y monitoring-plugins-contrib
  ln -s /usr/lib/nagios/ /usr/lib64/nagios
  https_proxy=http://fifi.arz.oeaw.ac.at:8080/ curl https://raw.githubusercontent.com/justintime/nagios-plugins/master/check_mem/check_mem.pl > /usr/lib/nagios/plugins/check_mem
  chmod +x /usr/lib/nagios/plugins/check_mem
  ```

### iSCSI

ARZ created a dedicated network card for connecting to the 10.6.1.201 NAS
and reserved the 10.6.1.235 IP address for it.

```
cat >> /etc/network/interfaces <<EOF
iface ens224 inet static
	address 10.6.1.235/24
EOF
```

Then set the iscsi daemon startup setting to the `automatic`.

```
sed -i -e 's/^node.startup = .*/node.startup = automatic/' /etc/iscsi/iscsid.conf
systemctl restart open-iscsi
```

This will make NAS partitions visible as /dev/sd*

Then just add them to the /etc/fstab

```
mkdir /mnt/arche-data
mkdir /mnt/arche-tmp
cat >> /etc/fstab <<EOL
/dev/disk/by-path/ip-10.6.1.201:3260-iscsi-iqn.2002-10.com.infortrend:raid.uid558545.401-lun-2 /mnt/arche-data xfs rw,_netdev,exec,async 0 0
/dev/disk/by-path/ip-10.6.1.201:3260-iscsi-iqn.2002-10.com.infortrend:raid.uid558545.401-lun-5 /mnt/arche-tmp  xfs rw,_netdev,exec,async 0 0
EOL
```

## Deployment

A set of custom systemd services calling docker-compose

* each service in '/opt/{service}`.
* each service definition:
  ```
  cat > /etc/systemd/system/arche-{service}.service <<EOL
  [Unit]
  Description=ARCHE Production Instance
  Wants=docker.service
  After=docker.service

  [Service]
  Type=simple
  Restart=always
  WorkingDirectory=/opt/arche
  ExecStart=/usr/bin/docker-compose up

  [Install]
  WantedBy=multi-user.target
  EOL
  systemctl daemon-reload
  systemctl start arche-{service}
  systemctl enable arche-{service}
  ```

### Cron jobs

Set up for the root user

```
0   1 * * * cd /opt && tar -czf /mnt/acdh_backup/901_backup/arche/opt_$(date +\%w).tgz *
0   1 * * * /usr/bin/docker exec core_core_1 /home/www-data/config/backup.sh > /opt/log/backup.log 2>&1
0   3 * * * /usr/bin/docker exec core_core_1 /home/www-data/config/updateFromRefSources.sh > /opt/log/updateFromRefSources.log 2>&1
0   2 * * 6 /usr/bin/docker exec core_core_1 /home/www-data/config/checks.sh sstuhec:2912GVSS https://arche.acdh.oeaw.ac.at/api/ > /opt/log/checks.log 2>&1
# cache pruning
30  * * * * /usr/bin/docker exec thumbnails_thumbnails_1 php -f /var/www/html/vendor/bin/arche-diss-cache-clear -- /var/www/html/config.yaml
31  * * * * /usr/bin/docker exec glb_glb_1 php -f /var/www/html/vendor/bin/arche-diss-cache-clear -- /var/www/html/config.yaml
32  * * * * /usr/bin/docker exec exif_exif_1 php -f /var/www/html/vendor/bin/arche-diss-cache-clear -- /var/www/html/config.yaml
# redeploy
*/5 * * * * /opt/pull_redeploy.sh > /opt/log/pull_redeploy.log 2>&1
```

### Proxy

* Images based on php/* image expose docker-compose-level env vars to the PHP
  therefore it is enough to include them in the docker-compose.yaml.
* For the arche-core the [run.sh](https://github.com/acdh-oeaw/arche-docker/blob/master/root/home/www-data/run.sh)
  appends the proxy vars to the /etc/apache2/envvars
* All ARCHE libraries and dissemination services honor http_proxy, https_proxy and no_proxy env var settings.

### Redeployment script:

The script is run trough root's cron and checks for newer docker image versions.

If a newer image is pulled, a corresponding service is restarted.

```
cat > /opt/pull_redeploy.sh <<EOL
#!/bin/bash
for i in \`docker ps --format '{{.Image}}' | grep -E '/|:'\` ; do 
    docker pull \$i
done
# if any running container runs an untagged image, restart
for i in `docker ps  --format '{{.Image}},{{.Names}}' | grep -v 'postgis/postgis' | grep -v 'ghcr.io/acdh-oeaw/loris' | grep -v 'acdhch/arche' | sed -e 's/^.*,//' -e 's/_.*//'` ; do
    echo "# Restarting arche-$i"
    systemctl restart arche-$i
done
docker image prune -f
EOL
chmod +x /opt/pull_redeploy.sh
```

### Backup

`acdh_backup` samba share is mounted under /mnt/acdh_backup and mapped to /home/www-data/backup of the `core_core_1` container.

The backup is run using a root's cronjob (see above).

### Domains

* arche.acdh.oeaw.ac.at (shibboleth)
  * Adjust https://rancher.acdh-dev.oeaw.ac.at/dashboard/c/c-m-6hwgqq2g/explorer/configmap/shibboleth-sp/arche-acdh?mode=edit#data
  * Redeploy https://rancher.acdh-dev.oeaw.ac.at/dashboard/c/c-m-6hwgqq2g/explorer/apps.deployment/shibboleth-sp/shibboleth-sp-nginx#pods
* Dissemination services deployed on the VM
  * Create an ingress in the `acdh-ch-proxy` namespace
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: arche-{dissServName}-acdh
      namespace: acdh-ch-proxy
      annotations:
        cert-manager.io/cluster-issuer: acdh-prod
        nginx.ingress.kubernetes.io/backend-protocol: HTTPS
      labels:
        ID: '{redmineIdOfTheDissServ}'
    spec:
      rules:
        - host: arche-{dissServName}.acdh.oeaw.ac.at
          http:
            paths:
              - backend:
                  service: 
                    name: nginx-unprivileged
                    port:
                      number: 8443
                path: /
                pathType: Prefix
      tls:
        - hosts:
            - arche-{dissServName}.acdh.oeaw.ac.at
          secretName: arche-{dissServName}-acdh-tls
    ```
  * Add proxy config to the
    https://rancher.acdh-dev.oeaw.ac.at/dashboard/c/c-m-6hwgqq2g/explorer/configmap/acdh-ch-proxy/arche-star-acdh?mode=edit#data
    ```
    server {
      server_name arche-{dissServName}.acdh.oeaw.ac.at;
      listen      8443 ssl;
      listen      [::]:8443 ssl;
      include     ssl/self-signed.conf;
      include     ssl/ssl-params.conf;
      location / {
        proxy_redirect off;
        proxy_set_header host $host;
        proxy_pass http://10.3.6.35:{dissServPort}/;
      }
    }
    ```
  * Redeploy the proxy
    https://rancher.acdh-dev.oeaw.ac.at/dashboard/c/c-m-6hwgqq2g/explorer/apps.deployment/acdh-ch-proxy/nginx-unprivileged

