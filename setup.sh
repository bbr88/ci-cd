#!/bin/bash

echo "Setting up the evnironment..."

FULL_CERT=$1
EMAIL=$2

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
if [ -z "$EMAIL" ] 
then
  echo "Email is required!"
  exit 1;
fi 

if [ -z "$FULL_CERT" ]
then
 echo "Full certificate will be acquired"
 FULL_CERT=true
else
 echo "Fake certificate will be acquired"
 FULL_CERT=false
fi


NGINX_WEB=/var/www/`hostname`/web
echo NGINX_WEB=$NGINX_WEB >> ./.env

CI_DOMAIN=`hostname`
echo CI_DOMAIN=$CI_DOMAIN >> ./.env

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

echo "Creating Nginx configuration"
sudo /bin/bash ./nginx/set-servername.sh `hostname`
sudo /bin/bash ./nginx/set-servername-cert.sh `hostname`

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

echo "Preparing data for a new Nginx certificate"
./getssl/getssl -c `hostname` -w ./

rm -fr ./getssl/`hostname`/getssl.cfg
touch ./getssl/`hostname`/getssl.cfg
chown 1001:1001 ./getssl/`hostname`/getssl.cfg

echo "ACL=('/var/www/`hostname`/web/.well-known/acme-challenge'
'ssh:server5:/var/www/`hostname`/web/.well-known/acme-challenge'
'ssh:sshuserid@server5:/var/www/`hostname`/web/.well-known/acme-challenge'
'ftp:ftpuserid:ftppassword:`hostname`:/web/.well-known/acme-challenge')" >> ./getssl/`hostname`/getssl.cfg

if [ FULL_CERT ]
then
  echo "CA=\"https://acme-v01.api.letsencrypt.org\"" >> ./getssl/`hostname`/getssl.cfg
else
  echo "CA=\"https://acme-staging-v02.api.letsencrypt.org/directory\"" >> ./getssl/`hostname`/getssl.cfg
fi

echo "ACCOUNT_EMAIL=\"$EMAIL\"" >> ./getssl/`hostname`/getssl.cfg

sudo docker-compose -f ./docker-compose-cert.yml up -d

echo "Waiting for Nginx to startup"
sleep 15

echo "Obtaining a new certificate"
./getssl/getssl -w ./ `hostname`

if [ -f "/var/www/`hostname`/web/.well-known/acme-challenge/json was blank" ]; then
    echo "Acme challenge not found! Trying to get a new challenge..."
    ./getssl/getssl `hostname`
fi


sudo docker-compose -f ./docker-compose-cert.yml down

sudo docker-compose up -d

echo "Done"
