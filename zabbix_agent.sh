#!/bin/bash
#Author: tony
#Description: installing zabbix_agent

RHEL_7_URI=http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm
RHEL_6_URI=http://repo.zabbix.com/zabbix/3.4/rhel/6/x86_64/zabbix-release-3.4-1.el6.noarch.rpm
RHEL_5_URI=http://repo.zabbix.com/zabbix/3.4/rhel/5/x86_64/zabbix-release-3.4-1.noarch.rpm
CONF_PATH=/etc/zabbix/zabbix_agentd.conf
INCLUDE_PATH=/etc/zabbix/zabbix_agentd.d
addr=

function versionCheck(){
			res=`cat /etc/redhat-release`
			OLD_IFS="$IFS"
			IFS=" "
			arr=($res)
			IFS="$OLD_IFS"
			if [ ${arr[2]:0:1}	-eq 7 ];then
				return 7
			elif [ ${arr[2]:0:1} -eq 6 ];then
				return 6
			else
				return 5
			fi
}

function Install(){
			yum -y install zabbix-agent
			mv  $CONF_PATH $CONF_PATH.bak
			echo  "PidFile=/var/run/zabbix/zabbix_agentd.pid" >> $CONF_PATH
			echo  "LogFile=/var/log/zabbix/zabbix_agentd.log" >> /etc/zabbix/zabbix_agentd.conf
			echo  "LogFileSize=0"  >> /etc/zabbix/zabbix_agentd.conf
			echo  "Server=$addr"  >> /etc/zabbix/zabbix_agentd.conf
			echo  "ServerActive=$addr" >> /etc/zabbix/zabbix_agentd.conf
			echo  "HostMetadataItem=system.uname" >> /etc/zabbix/zabbix_agentd.conf
			echo  "Include=/etc/zabbix/zabbix_agentd.d/"  >> /etc/zabbix/zabbix_agentd.conf
			echo  "UserParameter=custom.vfs.dev.read.ops[*],cat /proc/diskstats | grep $1 | head -1 | awk '{print $$4}' " >> $INCLUDE_PATH/userparameter.conf
			echo  "UserParameter=custom.vfs.dev.read.ms[*],cat /proc/diskstats | grep $1 | head -1 | awk '{print $$7}'  " >> $INCLUDE_PATH/userparameter.conf
			echo  "UserParameter=custom.vfs.dev.write.ops[*],cat /proc/diskstats | grep $1 | head -1 | awk '{print $$8}'  " >> $INCLUDE_PATH/userparameter.conf
			echo  "UserParameter=custom.vfs.dev.write.ms[*],cat /proc/diskstats | grep $1 | head -1 | awk '{print $$11}'  " >> $INCLUDE_PATH/userparameter.conf
			echo  "UserParameter=custom.vfs.dev.io.active[*],cat /proc/diskstats | grep $1 | head -1 | awk '{print $$12}'   " >> $INCLUDE_PATH/userparameter.conf
			echo  "UserParameter=custom.vfs.dev.io.ms[*],cat /proc/diskstats | grep $1 | head -1 | awk '{print $$13}'  " >> $INCLUDE_PATH/userparameter.conf
			echo  "UserParameter=custom.vfs.dev.read.sectors[*],cat /proc/diskstats | grep $1 | head -1 | awk '{print $$6}'  " >> $INCLUDE_PATH/userparameter.conf
			echo  "UserParameter=custom.vfs.dev.write.sectors[*],cat /proc/diskstats | grep $1 | head -1 | awk '{print $$10}' " >> $INCLUDE_PATH/userparameter.conf
}

versionCheck
if [ $? -eq 7 ];then
	rpm -ivh $RHEL_7_URI
	Install
	systemctl restart zabbix-agent
	systemctl enable zabbix-agent
elif [ $? -eq 6 ];then
	rpm -ivh $RHEL_6_URI
	Install
	service zabbix-agent restart
	chkconfig zabbix-agent on
else
	rpm -ivh $RHEL_5_URI
	Install
	service zabbix-agent restart
	chkconfig zabbix-agent on
fi

