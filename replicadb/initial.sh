#!/bin/bash

if [[ ! -d "replicadb/replicacnf" ]]; then
  mkdir replicadb/replicacnf
elif [[ ! -d "replicadb/replicainit" ]]; then
  mkdir replicadb/replicainit
fi

cat > replicadb/replicacnf/replicadb.cnf << EOF
[mariadb]
server_id=2            
log-basename=wordpress-db     
replicate_do_db=$WORDPRESS_DB_NAME
EOF

cat > replicadb/replicainit/replicainit.sql << EOF
CHANGE MASTER TO
  MASTER_HOST='master_db',
  MASTER_USER='$WORDPRESS_DB_USER',
  MASTER_PASSWORD='$WORDPRESS_DB_PASSWORD',
  MASTER_PORT=3306,
  MASTER_CONNECT_RETRY=10;
EOF