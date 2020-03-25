#!/bin/bash
while [ "`curl -i http://127.0.0.1/api/transaction -X POST 2>/dev/null | grep -c '201 Created'`" != "1" ]; do
    echo "Waiting for services to be up..."
    sleep 1
done
sleep 1
for i in `ls -1 /home/www-data/config/initScripts`; do
    if [ -x "/home/www-data/config/initScripts/$i" ]; then
        echo -e "##########\n# Running $i\n##########\n"
        /home/www-data/config/initScripts/$i
    fi
done

