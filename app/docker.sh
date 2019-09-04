#!/bin/bash -exu
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker

cd ~ && mkdir .docker
cat << EOF > ~/.docker/daemon.json
{
    "registry-mirrors": ["https://3vmiucf9.mirror.aliyuncs.com"]
}
EOF
