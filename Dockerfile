FROM jenkins/jenkins:lts
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

ARG docker_version=5:18.09.3~3-0~debian-stretch

USER root
RUN apt-get update && apt-get -y install \
    apt-transport-https \
    ca-certificates \
    zip \
    curl \
    gnupg2 \
    software-properties-common \
  && curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > \
    /tmp/dkey; apt-key add /tmp/dkey \
  && add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) \
    stable" \
  && apt-get update && apt-get -y install \
    docker-ce=${docker_version}

ENV UID_JENKINS=1001
ENV GID_JENKINS=1001

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
