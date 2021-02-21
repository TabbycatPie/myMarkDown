#!/bin/bash
read -p "Do you want to delete your Nextcloud contianer? (y/n):" answer
if [ $answer = 'y' ];then
echo "removing container ......"
docker rm -f nextcloud_main
fi
read -p "Do you want to also delete Nextcloud config folder?(y/n):" answer
if [ $answer = 'y' ];then
    echo "deleting /home/docker/nextcloud ...... "
    rm -rf /home/docker/nextcloud
fi
read -p 'Do you want to delete your mairadb container?(y/n):' answer
if [ $answer = 'y' ];then
echo "removing container ...... "
docker rm -f mariadb_main
fi
read -p 'Do you want to also delete database folder?(y/n)' answer
if [ $answer = 'y' ];then
    echo "deleting /home/docker/mariadb_main ...... "
    rm -rf /home/docker/mariadb_main
fi
read -p 'Do you want to also clear all images?(y/n)' answer
if [ $answer = 'y' ];then
    echo "removing images ...... "
    docker rmi $(docker images -qa)
fi
echo "Finish!"