#!/bin/bash

DOMAIN=$1

if [ -z "$DOMAIN" ]
then
 echo "Domain required"
 exit 1
fi

(
cat <<EOF
server {
  listen 80;
  server_name $DOMAIN;

  location ^~ /.well-known {
        allow all;
        default_type "text/plain";
        root /var/www/$DOMAIN/;
  }
}
EOF
) > ./nginx/default-cert.conf
