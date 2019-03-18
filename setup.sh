#!/bin/bash

echo "Setting up the evnironment..."

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."

NGINX_WEB=/var/www/`hostname`/web
echo NGINX_WEB=$NGINX_WEB >> ./.env

if [[ "$OSTYPE" == "linux-gnu" ]]; then export $(grep -v '^#' .env | xargs -d '\n') 
elif [[ "$OSTYPE" == "darwin"* ]]; then export $(grep -v '^#' .env | xargs -0) 
fi


if test -z "$NEXUS_DATA"
then
  echo "Environment variables have not been set"
  exit 1;
else
  echo "Nexus data is `echo $NEXUS_DATA`"
  echo "Environment variables successfully set"
fi

echo "Creating the folders required for Jenkins"
mkdir $JENKINS_DEFAULT_HOME
chown -R 1001:1001 ./*

echo "Creating the folders required for Nexus"
mkdir $NEXUS_DATA
chown -R 200:200 $NEXUS_DATA

echo "Creating the folders required for Sonarqube"
mkdir $SONARQUBE_CONF $SONARQUBE_DATA $SONARQUBE_EXT $SONARQUBE_PLUGINS $SONARQUBE_PSQL $SONARQUBE_PSQL_DATA
chown -R 999:999 $SONARQUBE_CONF $SONARQUBE_DATA $SONARQUBE_EXT $SONARQUBE_PLUGINS $SONARQUBE_PSQL $SONARQUBE_PSQL_DATA

echo "Creating the folders required for Nginx"
mkdir ./logs
mkdir $NGINX_LOGS
chown -R 1001:1001 $NGINX_LOGS

echo "Generating a new Nginx certificate"
./getssl/getssl -c `hostname`

echo "ACL=(
'/var/www/`hostname`/web/.well-known/acme-challenge'
'ssh:server5:/var/www/`hostname`/web/.well-known/acme-challenge'
'ssh:sshuserid@server5:/var/www/`hostname`/web/.well-known/acme-challenge'
'ftp:ftpuserid:ftppassword:`hostname`:/web/.well-known/acme-challenge')" >> ./getssl/`hostname`/getssl.cfg

echo "Done"
