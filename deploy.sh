#!/bin/bash
## ---------------------------------------------
## Deployment Standard Protocal:
## Shuting Down Process:
## 		offically shutdown application through API, return body MUST be upperletter "SUCCESS" or "FAIL",
## 		return code MUST be "200" if Application has been successfully been shutdown. scripts exception
## 		code was predefined below.
##      add here: 
##			4 application shuting down failed.
## Deployment Process:
##		deployment MUST include at least 3 phase, Shutdown-->Sleep-->StreamLinePKGNAME-->Stop-->PkgUpload-->Start
##		Printing startup logs as deploy phase finished.
## ---------------------------------------------
DATE=$(date +%Y%m%d%H%M)
INS_IP=()
INSNAME=()
USER=
PASSWD=
EUREKA_API=http://ipaddr:3000/eureka/apps/
APPNAME=FUNDS-BILL-REST
INSDIR=/data
PKGNAME=rest-funds-bill.jar
LOCAL_DIR=/data/prod-score/
LAST_PKG_DIR=/data/backup/prod-score/
KEY=/root/.ssh/prod_funds_score
## ---------------------------------------------
function shutdown(){
		return_body=(SUCCESS FAIL)
		res=$(curl -XPOST -H "Content-Type: application/json" -d '{"user":"","password":""}' http://$1)
		if [[ $res == ${return_body[0]} ]];then
			echo $res
		fi
		if [[ $res == ${return_body[1]} ]];then
			echo $res
			exit 4
		fi
}
function waitime(){
		echo "Ready to sleep for $1 seconds"
		sleep $1
}
function ins_deploy(){
		shutdown "$1:8080/offline"
		waitime 10
		scp $WORKSPACE/funds-bill-rest/target/rest-funds-bill-*.jar $PKGDIR/$PKGNAME
        ssh -i $KEY root@$1 "cd $INSDIR && ./spring.sh stop"
		scp -i $KEY ${LOCAL_DIR}/${PKGNAME} root@$1:$INSDIR
		ssh -i $KEY root@$1 "cd $INSDIR && ./spring.sh start"
}

function backup(){
		if [[ -e ${LAST_PKG_DIR}${DATE}.${PKG_NAME} ]];then
        	echo "Package Exist~"
        else
			scp ${LOCAL_DIR}${PKG_NAME} ${LAST_PKG_DIR}${DATE}.${PKG_NAME}
        fi
}
function SuccessPrint(){
		Project="Funds"
		ModuleName="bill"
		echo $Project $ModuleName "$@" "[Succeed!]"
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

function FailedPrint(){
		Project="Funds"
		ModuleName="bill"
		echo $Project $ModuleName "$@" "[Failed!]"
}
function Log_Print(){
       	ssh -i $KEY root@$1 "cd $INSDIR && tail -n 50 server.log"
}
function notify(){
		curl 'http://webhookaddress' -H 'Content-Type: application/json' -d '{"msgtype": "text", "text": {"content": "messagecontent"}}'
}
## ---------------------------------------------
##开始部署服务
backup
echo "Starting to Deploy instance ${pkg_name} 1....."
ins_deploy ${INS_IP[0]}
waitime 60
statu=`curl -u ${user}:${passwd} -H "Content-Type: application/json" -H "Accept: application/json" ${eureka_api}${app_name}/${instance_ID_1}|jq '.instance|.status'`
if [[ ${statu} == \"UP\" ]];then
	ins_deploy ${INS_IP[1]}
	waitime 60
    ins_2_status=`curl -u ${user}:${passwd} -H "Content-Type: application/json" -H "Accept: application/json" ${eureka_api}${app_name}/${instance_ID_2}|jq '.instance|.status'`
    if [[ ${ins_2_status} == \"UP\" ]];then
    	SuccessPrint "deploy"
        notify
        Log_Print ${INS_IP[0]}
        Log_Print ${INS_IP[1]}
    else
    	FailedPrint "instance 2 deploy"
    	Log_Print ${INS_IP[1]}
        exit 1
    fi
elif [[ ${statu} == \"DOWN\" ]];then
	FailedPrint "instance 1 deploy"
	Log_Print ${INS_IP[0]}
    exit 1
else
	echo "UNKOWN STATUS ${status}"
    Log_Print ${INS_IP[0]}
    exit 1
fi