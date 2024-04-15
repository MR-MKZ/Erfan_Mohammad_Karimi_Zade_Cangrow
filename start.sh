#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
    echo "Please run as root!"
    exit 1
else
    docker version

    if [[ $? -ne 0 ]]; then
  
    	apt update && apt upgrade -y
   	apt install docker.io -y
    
    fi

    docker compose version

    if [[ $? -ne 0 ]]; then
	mkdir -p ~/.docker/cli-plugins/
	curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
	chmod +x ~/.docker/cli-plugins/docker-compose
    fi

    docker compose up -d
fi
