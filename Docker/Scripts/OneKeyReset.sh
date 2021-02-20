#!/bin/bash
read -p 'do you want to clear your container:(y/n):' answer
if [ $answer = 'y' ];then
    echo "removing containers ...... "
    docker rm -f $(docker ps -qa)
    read -p 'Do you want to also clear all images?(y/n)' answer2
    if [ $answer2 = 'y' ];then
        echo "removing images ...... "
        docker rmi $(docker images -qa)
    else
        echo "Finished!"
    fi

else
    echo "Operation canceled."
fi