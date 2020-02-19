#!/bin/bash

# Preserve host user UID and GID
sed -i -E 's|www-data:(.*):/usr/sbin/nologin|www-data:\1:/bin/bash|g'  /etc/passwd
if [ "$USER_GID" != "" ]; then
    groupmod -g $USER_GID www-data 
    chgrp -R www-data /home/www-data
fi
if [ "$USER_UID" != "" ]; then
    usermod -u $USER_UID www-data
    chown -R www-data /home/www-data
fi
chown www-data:www-data /var/run/apache2 /var/run/postgresql /home/www-data/config

# Configuration initialization
if [ ! -d /home/www-data/config ] || [ -z "`ls -A /home/www-data/config`" ]; then
    ls -al /home/www-data/config
    if [ "$CFG_REPO_URL" == "" ]; then
        CFG_REPO_URL="https://github.com/zozlak/acdh-repo-docker-config.git"
    fi
    echo "cloning $CFG_REPO_URL"
    su -l www-data -c "git clone $CFG_REPO_URL /home/www-data/config"

    if [ "$CFG_BRANCH" != "" ]; then
        echo "changing branch to $CFG_BRANCH"
        su -l www-data -c "cd /home/www-data/config && git checkout $CFG_BRANCH"
    fi
fi

# Apache config from the configuration directory
if [ -d /home/www-data/config/sites-available ]; then
    rm -fR /etc/apache2/sites-available
    ln -s /home/www-data/config/sites-available /etc/apache2/sites-available
fi

# Repo config from the configuration directory
if [ ! -L /home/www-data/docroot/config.yaml ]; then
    su -l www-data -c 'ln -s /home/www-data/config/config.yaml /home/www-data/docroot/config.yaml'
    su -l www-data -c 'ln -s /home/www-data/config/composer.json /home/www-data/docroot/composer.json'
fi
# PHP libraries update
su -l www-data -c 'cd /home/www-data/docroot && composer update'
su -l www-data -c 'cp /home/www-data/docroot/vendor/acdh-oeaw/acdh-repo/index.php /home/www-data/docroot/index.php'
su -l www-data -c 'cp /home/www-data/docroot/vendor/acdh-oeaw/acdh-repo/.htaccess /home/www-data/docroot/.htaccess'

# Postgresql initialization
if [ ! -f /home/www-data/postgresql/postgresql.conf ]; then
    su -l www-data -c '/usr/lib/postgresql/11/bin/initdb -D /home/www-data/postgresql --auth=ident -U www-data --locale en_US.UTF-8'
    su -l www-data -c '/usr/lib/postgresql/11/bin/pg_ctl start -D /home/www-data/postgresql -l /home/www-data/log/postgresql.log'
    su -l www-data -c '/usr/bin/createdb www-data'
    su -l www-data -c '/usr/bin/psql -f /home/www-data/docroot/vendor/acdh-oeaw/acdh-repo/build/db_schema.sql'
    su -l www-data -c '/usr/bin/createuser repo'
    su -l www-data -c '/usr/bin/createuser guest'
    su -l www-data -c 'echo "GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO guest; GRANT USAGE ON SCHEMA public TO guest" | /usr/bin/psql'
    su -l www-data -c 'echo "GRANT SELECT, INSERT, DELETE, UPDATE, TRUNCATE ON ALL TABLES IN SCHEMA PUBLIC TO repo; GRANT USAGE ON SCHEMA public TO repo" | /usr/bin/psql'
    su -l www-data -c '/usr/lib/postgresql/11/bin/pg_ctl stop -D /home/www-data/postgresql'
fi
rm -f /home/www-data/postgresql/postmaster.pid

# Running supervisord
su -l www-data -c '/usr/bin/supervisord -c /home/www-data/supervisord.conf'

