#!/bin/bash
##---------------------------------------------
DATE=$(date +%Y%m%d%H%M)
ins_1_ip=10.206.59.94
ins_2_ip=10.206.59.95
user=admin
passwd=Funds2018
eureka_api=http://10.206.59.76:3000/eureka/apps/
app_name=FUNDS-ACTIVITY-REST
instance_ID_1=prod-funds-score-clock2:funds-activity-rest:8081
instance_ID_2=prod-funds-score-clock1:funds-activity-rest:8081
ins_dir=/data/activity
pkg_name=rest-funds-activity.jar
key=/root/.ssh/prod_funds_score
##---------------------------------------------
function shutdown(){
		##offically shutdown application through API, return body MUST be upperletter "SUCCESS" or "FAIL"
		##,return code MUST be "200" if Application has been successfully been shutdown, Exception
		##code was predefined below.
		return_body="SUCCESS"
		res=$(curl -XPOST -H "Content-Type: application/json" -d '{"user":"","password":""}' http://$1)
		if [[ $res == $return_body ]];then
			exit 0
		else
			echo "Unknow return body" $res
			exit 4
		fi
}

function waitime(){
		echo "Ready to sleep for $1 seconds"
		sleep $1
}
function ins_deploy(){
		##Instance Deployment,
		##deployment MUST include at least 3 phase, shutdown-->sleep-->AppKilled
		shutdown "$1:8081"
		waitime 10
        ssh -i $key root@$1 "cd $ins_dir && ./spring.sh stop"
		scp -i $key /data/prod-score/${pkg_name} root@$1:$ins_dir
		ssh -i $key root@$1 "cd $ins_dir && ./spring.sh start"
}

function backup(){
		PKGDIR=/data/prod-score/
		BAKDIR=/data/backup/prod-score/
		##Move outdated packages to backup directory
        if [[ -e ${BAKDIR}${DATE}.${pkg_name} ]];then
        	echo "Package Exist~"
        else
			scp ${PKGDIR}${pkg_name} ${BAKDIR}${DATE}.${pkg_name}
        fi
		##streamline and standardise package name
		scp $WORKSPACE/funds-activity-rest/target/funds-activity-rest-*-SNAPSHOT.jar $PKGDIR/$pkg_name
}

function Log_Print(){
		##Printing startup logs as deploy phase finished.
       	ssh -i $key root@$1 "cd $ins_dir && tail -n 50 server.log"
}

function SuccessPrint(){
		Project="Funds"
		ModuleName=""
		echo $Project $ModuleName "$@" "[Succeed!]"
}

function FailedPrint(){
		Project="Funds"
		ModuleName=""
		echo $Project $ModuleName "$@" "[Failed!]"	
}

##----------------------------------------------
##Starting to deploy application
backup
echo "Starting to Deploy instance ${pkg_name}....."
ins_deploy $ins_1_ip $instance_ID_1
waitime 45
statu=$(curl -u ${user}:${passwd} -H "Content-Type: application/json" -H "Accept: application/json" ${eureka_api}${app_name}/${instance_ID_1}|jq '.instance|.status')
if [[ ${statu} == \"UP\" ]];then
	ins_deploy $ins_2_ip $instance_ID_2
	waitime 45
    ins_2_status=$(curl -u ${user}:${passwd} -H "Content-Type: application/json" -H "Accept: application/json" ${eureka_api}${app_name}/${instance_ID_2}|jq '.instance|.status')
    if [[ ${ins_2_status} == \"UP\" ]];then
    	SuccessPrint "deploy"
        Log_Print $ins_1_ip
        Log_Print $ins_2_ip
    else
    	FailedPrint "instance 2 deploy"
    	Log_Print $ins_2_ip
        exit 1
    fi
elif [[ ${statu} == \"DOWN\" ]];then
	FailedPrint "instance 1 deploy"
	Log_Print $ins_1_ip
    exit 2
else
	echo "UNKOWN STATUS ${status}"
    Log_Print $ins_1_ip
    exit 3
fi
