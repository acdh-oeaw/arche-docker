#!/bin/bash
# TODO - wait for the whole app stack to go up in the right way
sleep 10
for i in `ls -1 /home/www-data/config/initScripts`; do
   echo -e "##########\n# Running $i\n##########\n"
   /home/www-data/config/initScripts/$i
done

