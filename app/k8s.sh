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
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker

cd ~ && mkdir .docker
cat << EOF > ~/.docker/daemon.json
{
    "registry-mirrors": ["https://3vmiucf9.mirror.aliyuncs.com"]
}
EOF

echo setting timezone...
timedatectl set-timezone Asia/Shanghai
systemctl stop firewalld.service
systemctl disable firewalld.service
sed -i 's/SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
setenforce 0


echo open ipvs...
ipvs_mod_dir="/usr/lib/modules/$(uname -r)/kernel/net/netfilter/ipvs"
for mod in $(ls $ipvs_mod_dir |grep  -o "^[^.]*"); do
    /sbin/modinfo -F filename $mod &>/dev/null
    if [ $? -eq 0 ];then
    /sbin/modprobe $mod
    fi
done

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubelet kubeadm kubectl
systemctl enable kubelet

sed -i '/ExecStart/a\ExecStartPost=\/usr\/sbin\/iptables -P FORWARD ACCEPT'  /usr/lib/systemd/system/docker.service

cat << EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# 放到vagrant的 shell里
# config.vm.provision "shell", inline: <<-SHELL
#       swapoff -a
#       sed -i 's/.*swap/#&/' /etc/fstab
#       sysctl -p /etc/sysctl.d/k8s.conf
# SHELL
