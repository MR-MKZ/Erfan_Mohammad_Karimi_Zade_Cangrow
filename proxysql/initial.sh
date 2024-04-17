#!/bin/bash

cat > proxysql/proxysql.cnf << EOF;
datadir="/var/lib/proxysql"

admin_variables=
{
    admin_credentials="admin:admin"
    mysql_ifaces="0.0.0.0:6032"
    refresh_interval=2000
    web_enabled=true
    web_port=6080
    stats_credentials="stats:admin"
}

mysql_variables=
{
    threads=4
    max_connections=2048
    default_query_delay=0
    default_query_timeout=36000000
    have_compress=true
    poll_timeout=2000
    interfaces="0.0.0.0:6033;/tmp/proxysql.sock"
    default_schema="$WORDPRESS_DB_NAME"
    stacksize=1048576
    server_version="5.1.30"
    connect_timeout_server=10000
    monitor_history=60000
    monitor_connect_interval=200000
    monitor_ping_interval=200000
    ping_interval_server_msec=10000
    ping_timeout_server=200
    commands_stats=true
    sessions_sort=true
    monitor_username="root"
    monitor_password="$WORDPRESS_DB_PASSWORD"
    monitor_galera_healthcheck_interval=2000
    monitor_galera_healthcheck_timeout=800
}

mysql_galera_hostgroups =
(
    {
        writer_hostgroup=10
        reader_hostgroup=20
        max_writers=1
        writer_is_also_reader=0
        max_transactions_behind=30
        active=1
    }
)

mysql_servers =
(
    { address="master_db" , port=3306 , hostgroup=10, max_connections=100 },
    { address="replica_db" , port=3306 , hostgroup=20, max_connections=100 }
)

mysql_query_rules =
(
    {
        rule_id=100
        active=1
        match_pattern="^SELECT .* FOR UPDATE"
        destination_hostgroup=10
        apply=1
    },
    {
        rule_id=200
        active=1
        match_pattern="^SELECT .*"
        destination_hostgroup=20
        apply=1
    },
    {
        rule_id=300
        active=1
        match_pattern=".*"
        destination_hostgroup=10
        apply=1
    }
)

mysql_users =
(
    { username = "root", password = "$WORDPRESS_DB_PASSWORD", default_hostgroup = 10, transaction_persistent = 0, active = 1 }
)
EOF

# cat > proxysql/proxysql.cnf << EOF;
# datadir="/var/lib/proxysql"
# errorlog="/var/lib/proxysql/proxysql.log"
 
# admin_variables={
# admin_credentials="admin:admin"
# mysql_ifaces="0.0.0.0:6032"
# }
 
# mysql_variables={
# monitor_username="root"
# monitor_password="$WORDPRESS_DB_PASSWORD"
# monitor_read_only_timeout=60000
# monitor_connect_timeout=60000
# monitor_ping_timeout=60000
# mysql_ping_timeout_server=500
# }
 
# mysql_servers=({
# hostname="master_db"
# port=3306
# hostgroup=1
# },{
# hostname="replica_db"
# port=3306
# hostgroup=2
# })
 
# mysql_users=({
# username="root"
# password="$WORDPRESS_DB_PASSWORD"
# default_hostgroup=1
# })
 
# mysql_replication_hostgroups=({
# writer_hostgroup=1
# reader_hostgroup=2
# check_type="innodb_read_only"
# comment="Aurora Wordpress"
# })
# EOF