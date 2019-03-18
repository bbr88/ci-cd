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
  return 301 https://$host$request_uri;
}

server {

    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;

    location ^~ /jenkins/ {

        proxy_set_header        Host $host:$server_port;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;

        # Fix the "It appears that your reverse proxy set up is broken" error.
        proxy_pass              http://jenkins:8080/jenkins/;
        proxy_read_timeout      90;

        proxy_redirect          http://jenkins:8080/jenkins https://$DOMAIN/jenkins;

        # Required for new HTTP-based CLI
        proxy_http_version 1.1;
        proxy_request_buffering off;
        proxy_buffering off; # Required for HTTP-based CLI to work over SSL
        # workaround for https://issues.jenkins-ci.org/browse/JENKINS-45651
        add_header 'X-SSH-Endpoint' '$DOMAIN:50022' always;
    }

    location ^~ /nexus/ {
        proxy_set_header        Host $host:$server_port;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;

        # Fix the "It appears that your reverse proxy set up is broken" error.
        proxy_pass              http://nexus:8081/nexus/;
        proxy_read_timeout      90;

        proxy_redirect          http://nexus:8081/nexus https://$DOMAIN/nexus;
    }

    location ^~ /sonarqube/ {
        proxy_set_header        Host $host:$server_port;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;

        # Fix the "It appears that your reverse proxy set up is broken" error.
        proxy_pass              http://sonarqube:9000/sonarqube/;
        proxy_read_timeout      90;

        proxy_redirect          http://sonarqube:9000/sonarqube https://$DOMAIN/sonarqube;
    }

    location ^~ /.well-known {
        allow all;
        default_type "text/plain";
        root /var/www/$DOMAIN/;
    }
}
EOF
) > ./nginx/default.conf
