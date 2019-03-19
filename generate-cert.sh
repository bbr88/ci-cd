#!/bin/bash

./getssl/getssl `hostname`
./getssl/getssl `hostname`

NGINX_SSL_CERT=./getssl/`hostname`/`hostname`.crt
NGINX_SSL_KEY=./getssl/`hostname`/`hostname`.key

echo NGINX_SSL_CERT=$NGINX_SSL_CERT >> ./.env
echo NGINX_SSL_KEY=$NGINX_SSL_KEY >> ./.env

docker-compose up -d nginx
