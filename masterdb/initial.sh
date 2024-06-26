#!/bin/bash

if [[ ! -d "masterdb/masterinit" ]]; then
  mkdir masterdb/masterinit
fi

cat > masterdb/masterinit/masterinit.sql << EOF
CREATE USER '$WORDPRESS_DB_USER'@'%' IDENTIFIED BY '$WORDPRESS_DB_PASSWORD';
GRANT REPLICATION SLAVE ON *.* TO '$WORDPRESS_DB_USER'@'%';
CREATE DATABASE $WORDPRESS_DB_NAME;
EOF