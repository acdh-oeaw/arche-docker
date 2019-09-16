#!/bin/bash
sed -i -E 's|www-data:(.*):/usr/sbin/nologin|www-data:\1:/bin/bash|g'  /etc/passwd
if [ "$USER_GID" != "" ]; then
    groupmod -g $USER_GID www-data 
    chgrp -R www-data /home/www-data
fi
if [ "$USER_UID" != "" ]; then
    usermod -u $USER_UID www-data
    chown -R www-data /home/www-data
fi
chown www-data:www-data /var/run/apache2 /var/run/postgresql
if [ ! -d /home/www-data/acdh-repo/.git ]; then
    su -l www-data -c 'git clone --no-checkout https://github.com/zozlak/acdh-repo.git /home/www-data/gitTmp && mv /home/www-data/gitTmp/.git /home/www-data/acdh-repo/ && rm -fR /home/www-data/gitTmp && cd /home/www-data/acdh-repo/ && git checkout master'
    su -l www-data -c 'ln -s /home/www-data/config.yaml /home/www-data/acdh-repo/config.yaml'
fi
if [ ! -f /home/www-data/postgresql/postgresql.conf ]; then
    su -l www-data -c '/usr/lib/postgresql/11/bin/initdb -D /home/www-data/postgresql --auth=ident -U www-data'
    su -l www-data -c '/usr/lib/postgresql/11/bin/pg_ctl start -D /home/www-data/postgresql -l /home/www-data/log/postgresql.log'
    su -l www-data -c '/usr/bin/createdb www-data'
    su -l www-data -c '/usr/bin/psql -f /home/www-data/acdh-repo/dbschema/db_schema.sql'
    su -l www-data -c '/usr/bin/createuser repo'
    su -l www-data -c '/usr/bin/createuser guest'
    su -l www-data -c 'echo "GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO guest; GRANT USAGE ON SCHEMA public TO guest" | /usr/bin/psql'
    su -l www-data -c 'echo "GRANT SELECT, INSERT, DELETE, UPDATE, TRUNCATE ON ALL TABLES IN SCHEMA PUBLIC TO repo; GRANT USAGE ON SCHEMA public TO repo" | /usr/bin/psql'
    su -l www-data -c '/usr/lib/postgresql/11/bin/pg_ctl stop -D /home/www-data/postgresql'
fi
su -l www-data -c 'cd /home/www-data/acdh-repo && composer update'
su -l www-data -c '/usr/bin/supervisord -c /home/www-data/supervisord.conf'

