#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

IP=$1


# editing kubelet configuration
#echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$IP\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo sed -i "s/ARGS=/ARGS=--node-ip=$IP/g" /etc/default/kubelet

#systemctl daemon-reload
#systemctl restart kubelet



kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address $IP --ignore-preflight-errors all >> data

mkdir -p $HOME/.kube
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config



cat data | grep kubeadm | grep join >> join_data
#rm data

