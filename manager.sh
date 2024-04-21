#!/bin/bash

set -o allexport
source ".env"
set +o allexport

Help() {
    echo "Manager.sh is a file to help you for managing this wordpress website."
    echo
    echo "Syntax: manager.sh [command]"
    echo "commands:"
    echo "start        setup your system and start containers"
    echo "stop         stop containers"
    echo "remove       remove containers"
    echo "db-queries   connection distribution overview for all hostgroups (you can use to check proxysql routing is ok or not)"
    echo "pull-theme   get new version of mkz-theme"
    echo
}

StartContainers() {

    if ! command -v docker; then

        apt update && apt upgrade -y
        apt install docker.io -y

    fi

    webhook &> /dev/null

    if [[ $? -ne 0 ]]; then
        wget https://github.com/adnanh/webhook/releases/download/2.8.1/webhook-linux-amd64.tar.gz
        tar -xvf webhook-linux-amd64.tar.gz
        mv webhook-linux-amd64/webhook /usr/local/bin
        rm -r -f webhook-linux-amd64
    fi

    docker compose &> /dev/null

    if [[ $? -ne 0 ]]; then
        echo "[Action]: Installing docker compose plugin."
        mkdir -p ~/.docker/cli-plugins/
        curl -SL https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
        chmod +x ~/.docker/cli-plugins/docker-compose
        apt install docker-compose -y
    fi

    chmod +x ./masterdb/initial.sh
    bash -c ./masterdb/initial.sh

    if [[ $? -eq 0 ]]; then
        chmod +x ./replicadb/initial.sh
        bash -c ./replicadb/initial.sh

        if [[ $? -eq 0 ]]; then
            chmod +x ./proxysql/initial.sh
            bash -c ./proxysql/initial.sh

            if [[ $? -eq 0 ]]; then
                echo "[Action]: Running containers started"
                PullWordpressTheme
                docker compose up -d
                # crontab -r &> /dev/null
                # COMMAND="cd $PWD && ./wp/pull-theme.sh &>> ./wp/pull-theme.log"
                # SCHEDULE="*/5 * * * *"
                # date &>> ./wp/pull-theme.log
                # (crontab -l; echo "$SCHEDULE $COMMAND") | crontab -
            else
                echo "running proxysql configure file failed! please try again."
                exit 1
            fi
        else
            echo "running replicadb configure file failed! please try again."
            exit 1
        fi
    else
        echo "running masterdb configure file failed! please try again."
        exit 1
    fi
}

StopContainers() {
    echo "[Action]: Stopping containers started"
    docker compose stop
}

RemoveContainers() {
    echo "[Action]: Removing containers started"
    docker compose down
    rm -r -f wordpress
    rm -r -f ./masterdb/logs
    rm -r -f ./replicadb/logs
    rm -r -f ./wp/themes/*
    # crontab -r &> /dev/null
    # rm -r -f ./wp/pull-theme.log
}

ShowConnectionPoolTable() {
    docker exec -it database_proxy mysql -uroot -p123456789 -hproxysql -P6032 -e 'select hostgroup, srv_host, status, ConnUsed, MaxConnUsed, Queries from stats.stats_mysql_connection_pool order by srv_host;'
    if [[ $? -ne 0 ]]; then
        echo "[!]: Is project running? try manager.sh start"
        exit 1
    fi
}

PullWordpressTheme() {
    chmod +x ./wp/pull-theme.sh
    bash -c ./wp/pull-theme.sh
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
    elif [[ $1 = "db-queries" ]]; then
        ShowConnectionPoolTable
    elif [[ $1 = "pull-theme" ]]; then
        PullWordpressTheme
    else
        Help
    fi
fi
