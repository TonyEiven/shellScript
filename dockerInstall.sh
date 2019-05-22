#!/bin/bash

# Description: install docker-ce version on your OS

# Defined etcdInstallation variables
etcdClusterIpRange=(192.168.1.1 192.168.1.2 192.168.1.3)
nodeName='node1'
currentNodeIpAddr='192.168.1.1'

# Remove old version
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
				  
# Setup repository
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Installing
yum install docker-ce docker-ce-cli containerd.io
systemctl start docker

# Download kubernetes and unpack
SERVER_DIR=/k8s/server
CLIENT_DIR=/k8s/client
NODE_DIR=/k8s/node
Ver="v1.14.2"
MainSite="https://dl.k8s.io"
Arch=amd64
if [[ ! -e $SERVER_DIR ]] || [[ ! -e $CLIENT_DIR ]] || [[ ! -e $NODE_DIR]];then
	mkdir -p /k8s/{node,client,server}
fi
pushd $SERVER_DIR
wget $MainSite/$Ver/kubernetes-server-linux-$Arch.tar.gz && tar -zxf $MainSite/$Ver/kubernetes-server-linux-$Arch.tar.gz
mv $MainSite/$Ver/kubernetes/server/bin/* $MainSite/$Ver/ && rm -rf $MainSite/$Ver/kubernetes
popd

pushd $CLIENT_DIR
wget $MainSite/$Ver/kubernetes-client-linux-$Arch.tar.gz && tar -zxf $MainSite/$Ver/kubernetes-client-linux-$Arch.tar.gz
mv $MainSite/$Ver/kubernetes/client/bin/* $MainSite/$Ver/ && rm -rf $MainSite/$Ver/kubernetes
popd

pushd $NODE_DIR
wget $MainSite/$Ver/kubernetes-node-linux-$Arch.tar.gz && tar -zxf $MainSite/$Ver/kubernetes-node-linux-$Arch.tar.gz
mv $MainSite/$Ver/kubernetes/node/bin/* $MainSite/$Ver/ && rm -rf $MainSite/$Ver/kubernetes
popd

export PATH=$PATH:/k8s/server:/k8s/node:/k8s/client
echo "PATH=$PATH:/k8s/server:/k8s/node:/k8s/client" >> /etc/profile


function _installEtcdCluster(){
	# Install etcd by using yum whether it's installed or not.
	yum -y install etcd >> /dev/null
	token='aGVsbG93b3JsZAo'
	state='new'
	cluster=''
	for n in $(seq 1 ${#etcdClusterIpRange[@]});
	do
		cluster = $cluster$nodeName$n"=http://"${etcdClusterIpRange[$n]}:2380","
	done
	cluster=${cluster/%,/}  #trim comma in the tail
	# Backup etcd.conf
	mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.bak
	cat >> /etc/etcd/etcd.conf <<EOF
	ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
	ETCD_NAME="${nodeName}"
	ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${currentNodeIpAddr}:2380"
	ETCD_LISTEN_PEER_URLS="http://${currentNodeIpAddr}:2380"
	ETCD_ADVERTISE_CLIENT_URLS="http://${currentNodeIpAddr}:2379,http://127.0.0.1:2379"
	ETCD_LISTEN_CLIENT_URLS="http://${currentNodeIpAddr}:2379,http://127.0.0.1:2379"
	ETCD_INITIAL_CLUSTER="${cluster}"
	ETCD_INITIAL_CLUSTER_STATE="${state}"
	ETCD_INITIAL_CLUSTER_TOKEN="${token}"
	EOF
}
