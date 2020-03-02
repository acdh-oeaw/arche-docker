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
if [ -d /home/www-data/config/sites-enabled ]; then
    rm -fR /etc/apache2/sites-enabled
    ln -s /home/www-data/config/sites-enabled /etc/apache2/sites-enabled
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

# User init scripts
rm -f /home/www-data/postgresql/postmaster.pid

for i in `ls -1 /home/www-data/config/run.d`; do
    if [ -x "/home/www-data/config/run.d/$i" ]; then
        echo -e "##########\n# Running /home/www-data/config/run.d/$i\n##########\n"
        /home/www-data/config/run.d/$i
    fi
done

# Running supervisord
echo -e "##########\n# Starting supervisord\n##########\n"
su -l www-data -c '/usr/bin/supervisord -c /home/www-data/supervisord.conf'

