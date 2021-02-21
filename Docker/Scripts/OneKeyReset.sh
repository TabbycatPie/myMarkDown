#!/bin/bash
read -p 'Do you want to delete your mairadb container?:(y/n):' answer
if [ $answer = 'y' ];then
echo "removing container ...... "
docker rm -f mariadb_main
fi
read -p 'Do you want to also delete database folder?(y/n)' answer3
if [ $answer3 = 'y' ];then
    echo "deleting /home/docker/mariadb_main ...... "
    rm -rf /home/docker/mariadb_main
fi
read -p 'Do you want to also clear all images?(y/n)' answer2
if [ $answer2 = 'y' ];then
    echo "removing images ...... "
    docker rmi $(docker images -qa)
fi
echo "Finish!"