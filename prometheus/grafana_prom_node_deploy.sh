#!/bin/bash
# Author: TonyEiven
# Email_Address: hzxub@tairanchina.com
# Version: 1.0
# Prometheus_Version: 2.3.1
# Go_version: go1.10.3
# Grafana_Version: 5.1.4 (commit: a5fe24fcc)
# Node_Exporter Version: 0.16.0 (branch: HEAD, revision: d42bd70f4363dced6b77d8fc311ea57b63387e4f)

# The path might be better use a independant directory,
WORKDIR="/data"

LINK="https://s3-us-west-2.amazonaws.com/grafana-releases/release"
# Download link: https://prometheus.io/download/
# Grafana Reference link: http://docs.grafana.org/installation/rpm/
# Prometheus Reference link: https://prometheus.io/docs/

GRAFANA_PKG="grafana-5.1.4-1.x86_64.rpm"
PROMETHEUS_PKG="prometheus-2.3.2.linux-amd64.tar.gz"
NODE_EXPORTER_PKG="node_exporter-0.16.0.linux-amd64.tar.gz"
MYSQL_EXPORTER_PKG="mysql_exporter.tar.gz"
PROMETHEUS_SCRIPT="prometheus.sh"
NODE_SCRIPT="node.sh"
MYSQL_SCRIPT="mysqlexporter.sh"
LOG_DIR="/data/prometheus/logs"

# if the directory doesn't exist, creat it.
if [ ! -d "$WORKDIR" ];then
	mkdir -p $WORKDIR
fi

# Max open files
OPEN_FILE_LIMIT=65536
ulimit -n $OPEN_FILE_LIMIT


function log_failure_msg() {
    echo "$@" "[ FAILED ]"
}

function log_success_msg() {
    echo "$@" "[ OK ]"
}
function grafana_install(){
	/usr/sbin/grafana-server -v
	ISEXIST=$?
	if [[ $ISEXIST = 0 ]];then
		echo "Grafana has been installed already.."
		exit 1
	fi
	#download package from $LINK address
	if [ ! -e $PWD/$GRAFANA_PKG ];then
		wget $LINK/$GRAFANA_PKG
		res=$?
		if [[ $? != 0 ]];then
			echo "download $GRAFANA_PKG failed, please check your internet connection availibility."
		fi
	fi
	yum -y localinstall $PWD/grafana-5.1.4-1.x86_64.rpm > /dev/null
	res=$?
	if [[ $? != 0 ]];then
		log_failure_msg "grafana installed"
		exit 2
	fi
	## Starting grafana service
	echo "Starting Grafana service...."
	service grafana-server start > /dev/null
	STATUS=$?
	local PID=$(cat /var/run/grafana-server.pid)
	if [[ $STATUS != 0 ]];then
		log_failure_msg "grafana installed"
		exit 3
	fi
	rm -rf $PWD/grafana-5.1.4-1.x86_64.rpm
	log_success_msg "grafana successfully installed, PID is $(PID)"
}

function prometheus_install(){
	if [[ $(pgrep -f prometheus) ]];then
		echo "Prometheus has been installed already.."
		exit 1
	fi
	if [ ! -e "$PROMETHEUS_PKG" ];then
		echo "package $PROMETHEUS_PKG doesn't exist, please download it from https://prometheus.io/download/ first."
		exit 1
	fi
	if [ ! -d $(dirname $LOG_DIR) ];then
		mkdir -p $(dirname $LOG_DIR)
	fi
	tar -zxf $PROMETHEUS_PKG -C $(dirname $LOG_DIR)
	rm -rf $PROMETHEUS_PKG
	if [ ! -e $PROMETHEUS_SCRIPT ];then
		echo "prometheus scripts doesn't exist!"
		echo "Use binary file in $(dirname $LOG_DIR)to running it."
	else
		mv $PWD/$PROMETHEUS_SCRIPT /etc/init.d/ && chmod +x /etc/init.d/$PROMETHEUS_SCRIPT
		log_success_msg "prometheus installed"
		echo "Please use /etc/init.d/prometheus.sh script running it, enjoy your journey in prometheus!"
	fi
}

function node_exporter_install(){
	if [[ $(pgrep -f node_exporter) ]];then
		echo "Node_exporter has been installed already.."
		exit 1
	fi
	if [ ! -e "$NODE_EXPORTER_PKG" ];then
		echo "$NODE_EXPORTER_PKG doesn't exist, please download it from https://prometheus.io/download/ first."
		exit 1
	fi
	tar -zxf $NODE_EXPORTER_PKG -C $WORKDIR
	mv $WORKDIR/node_exporter* $WORKDIR/node_exporter
	rm -rf $NODE_EXPORTER_PKG
	if [ ! -e $NODE_SCRIPT ];then
		echo "node_exporter scripts doesn't exist!"
		echo "Use binary file in $WORKDIR/node_exporter to running it."
	else
		mv $PWD/$NODE_SCRIPT /etc/init.d/ && chmod +x /etc/init.d/$NODE_SCRIPT
		log_success_msg "node_exporter installed"
		echo "Please use /etc/init.d/node.sh script running node_exporter, enjoy your journey in node_exporter."
	fi
}

function mysql_exporter_install(){
	if [[ $(pgrep -f mysql_exporter) ]];then
		echo "mysql_exporter has been installed already.."
		exit 1
	fi
	if [ ! -e "$MYSQL_EXPORTER_PKG" ];then
		echo "$MYSQL_EXPORTER_PKG doesn't exist, please download it from https://prometheus.io/download/ first."
		exit 1
	fi
	tar -zxf $MYSQL_EXPORTER_PKG -C $WORKDIR
	#mv $WORKDIR/mysql_exporter* $WORKDIR/mysql_exporter
	rm -rf $MYSQL_EXPORTER_PKG
	if [ ! -f "$PWD/my.cnf" ];then
		echo "Mysql connection configure file doesn't exist, please create it first."
		exit 3
	fi
	mv $PWD/my.cnf /etc/.my.cnf
	if [ ! -e $MYSQL_SCRIPT ];then
		echo "mysql_exporter scripts doesn't exist!"
		echo "Use binary file in $WORKDIR/mysql_exporter to running it."
	else
		mv $PWD/$MYSQL_SCRIPT /etc/init.d/ && chmod +x /etc/init.d/$MYSQL_SCRIPT
		log_success_msg "mysql_exporter installed"
		echo "Please use /etc/init.d/mysqlexporter.sh script running mysql_exporter, enjoy your journey in mysql_exporter."
	fi
	sed -i '2s/^/#&/' /etc/hosts
}
# Check if grafana is installed or not.
case $1 in
	1)
		grafana_install
		;;
	2)
		prometheus_install
		;;
	3)
		node_exporter_install
		;;
	4)
		mysql_exporter_install
		;;
	*)
		echo "Usage: $0 {1|2|3|4}"
		echo "Elucidation: {1-grafana|2-prometheus|3-node_exporter|4-mysql_exporter}"
		exit 2
		;;
esac

