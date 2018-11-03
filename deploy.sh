#!/bin/bash
##admin_1_ip=""
##admin_2_ip=""
##定义基础变量
##---------------------------------------------
Basename=message-admin
dates=`date '+%Y-%m-%d'`
ins_1_ip=
ins_2_ip=
user=
passwd=
eureka_api=http://ipaddress:30000/eureka/apps/
app_name=MESSAGE-ADMIN
instance_ID_1=iapddress:message-admin:7070
instance_ID_2=ipaddress:message-admin:7070
ins_dir=/data/admin/
pkg_name=admin.jar
##---------------------------------------------
function ins_deploy(){
		##部署实例
        ssh -i /root/.ssh/uat-focus-es root@$1 "cd $ins_dir && ./spring.sh stop"
		scp -i /root/.ssh/uat-focus-es $WORKSPACE/service/kernel/admin/target/${pkg_name} root@$1:$ins_dir
		ssh -i /root/.ssh/uat-focus-es root@$1 "cd $ins_dir && ./spring.sh start"
}

function backup(){
		message_jenkins_stor_dir=/data/deploy/message/
		remote_stor_dir=/data/csp-message/
		last_pkg_bak_dir=/data/deploy/backup/message/
        ##老旧jar包备份
		scp ${message_jenkins_stor_dir}${pkg_name} ${last_pkg_bak_dir}
		##jar包本地存放目录
		scp $WORKSPACE/service/kernel/admin/target/${pkg_name} $message_jenkins_stor_dir
		##jar包远程存放目录
		scp -i /root/.ssh/uat-focus-es $WORKSPACE/service/kernel/admin/target/${pkg_name} root@10.200.147.9:$remote_stor_dir
        scp -i /root/.ssh/prod-mijin $WORKSPACE/service/kernel/admin/target/${pkg_name} upload@ipaddress:$remote_stor_dir
        
}

function Log_Print(){
		##输出日志
       	ssh -i /root/.ssh/uat-focus-es root@$1 "cd $ins_dir/logs/${Basename} && tail -n 50 ${dates}.log"
}
##----------------------------------------------
##开始部署admin服务
echo "Starting to Deploy instance admin 1....."
ins_deploy $ins_1_ip
begin_time=$(date +%s)
statu=$(curl -u ${user}:${passwd} -H "Content-Type: application/json" -H "Accept: application/json" ${eureka_api}${app_name}/${instance_ID_1}|jq '.instance|.status')
until [[ ${statu} == \"UP\" ]]
do
    statu=$(curl -u ${user}:${passwd} -H "Content-Type: application/json" -H "Accept: application/json" ${eureka_api}${app_name}/${instance_ID_1}|jq '.instance|.status')
    end_time=$(date +%s)
    time_lag=$(expr $end_time - $begin_time)
    if [[ $time_lag -gt 60 ]];then
    	echo "Get Status of Instance 1 Timeout."
        echo "CSP Message module ${pkg_name} instance 1 deploy failed. Please check the output messages."
        Log_Print $ins_1_ip
        exit 1
    fi
done
Log_Print $ins_1_ip
echo "Starting to Deploy instance admin 2....."
ins_deploy $ins_2_ip
begin_time=$(date +%s)
ins_2_status=$(curl -u ${user}:${passwd} -H "Content-Type: application/json" -H "Accept: application/json" ${eureka_api}${app_name}/${instance_ID_2}|jq '.instance|.status')
until [[ ${ins_2_status} == \"UP\" ]]
do
    ins_2_status=$(curl -u ${user}:${passwd} -H "Content-Type: application/json" -H "Accept: application/json" ${eureka_api}${app_name}/${instance_ID_2}|jq '.instance|.status')
    end_time=$(date +%s)
    time_lag=$(expr $end_time - $begin_time)
    if [[ $time_lag -gt 60 ]];then
    	echo "Get Status of Instance 2 Timeout."
        echo "CSP Message module ${pkg_name} instance 2 deploy failed. Please check the output messages."
        Log_Print $ins_2_ip
        exit 1
    fi
done
echo "CSP message module ${pkg_name} have successfully been deployed."
Log_Print $ins_2_ip
backup
