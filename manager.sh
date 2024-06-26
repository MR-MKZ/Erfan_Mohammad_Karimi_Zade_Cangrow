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

CreateWebhookService()
{
cat > /etc/systemd/system/webhook.service << EOF
[Unit]
Description=Github Webhook
Documentation=https://github.com/adnanh/webhook
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/webhook -verbose -hotreload -hooks /opt/webhooks/hooks.json -port 9000 -http-methods post

[Install]
WantedBy=multi-user.target
EOF
chmod 644 /etc/systemd/system/webhook.service
systemctl enable webhook.service
systemctl start webhook.service
}

StartContainers() {

    if ! command -v docker; then
        clear
        apt update && apt upgrade -y
        apt install docker.io -y

    fi

    webhook -version &> /dev/null

    if [[ $? -ne 0 ]]; then
        clear
        wget https://github.com/adnanh/webhook/releases/download/2.8.1/webhook-linux-amd64.tar.gz
        tar -xvf webhook-linux-amd64.tar.gz
        mv webhook-linux-amd64/webhook /usr/local/bin
        rm -r -f webhook-linux-amd64
        rm -r -f webhook-linux-amd64.tar.gz
        mkdir /opt/webhooks
        cp hooks.json /opt/webhooks
        CreateWebhookService
    fi

    systemctl list-units --full -all | grep -Fq "webhook.service"

    if [[ $? -ne 0 ]]; then
        clear
        CreateWebhookService
    fi

    docker compose &> /dev/null

    if [[ $? -ne 0 ]]; then
        clear
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
                clear
                docker compose up -d
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
    systemctl stop webhook.service
    systemctl disable webhook.service
    rm /etc/systemd/system/webhook.service
    systemctl daemon-reload
    systemctl reset-failed
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
