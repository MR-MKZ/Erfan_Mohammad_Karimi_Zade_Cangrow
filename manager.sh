#!/bin/bash

set -o allexport
source ".env"
set +o allexport

Help()
{
   echo "Manager.sh is a file to help you for managing this wordpress website."
   echo
   echo "Syntax: manager.sh [command]"
   echo "commands:"
   echo "start     setup your system and start containers"
   echo "stop      stop containers"
   echo "remove    remove containers"
   echo
}

StartContainers()
{
    docker version

    clear

    if [[ $? -ne 0 ]]; then
  
    	apt update && apt upgrade -y
   	    apt install docker.io -y
    
    fi

    docker compose version

    clear

    if [[ $? -ne 0 ]]; then
        echo "[Action]: Installing docker compose plugin."
        mkdir -p ~/.docker/cli-plugins/
        curl -SL https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
        chmod +x ~/.docker/cli-plugins/docker-compose
    fi

    chmod +x ./masterdb/initial.sh
    bash -c ./masterdb/initial.sh
    
    chmod +x ./replicadb/initial.sh
    bash -c ./replicadb/initial.sh

    echo "[Action]: Running containers started"

    docker compose up -d
}

StopContainers()
{
    echo "[Action]: Stopping containers started"
    docker compose stop
}

RemoveContainers()
{
    echo "[Action]: Removing containers started"
    docker compose down
    rm -r -f wordpress
    rm -r -f ./masterdb/logs
    rm -r -f ./replicadb/logs
}

if [[ $(id -u) -ne 0 ]]; then
    echo "Please run program as root!"
    exit 1
else
    if [[ $1 = "start" ]]; then
        StartContainers
    elif [[ $1 = "stop" ]]; then
        StopContainers
    elif [[ $1 = "remove" ]]; then
        RemoveContainers
    else
        Help
    fi
fi