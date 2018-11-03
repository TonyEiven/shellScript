#!/bin/bash
##---------------------------------------------
DATE=$(date +%Y%m%d%H%M)
ins_1_ip=10.200.151.11
ins_2_ip=10.200.151.8
user=admin
passwd=123456
eureka_api=http://10.200.151.7:3000/eureka/apps
app_name=FUNDS-REDPACKET-REST
instance_ID_1=dev-ggzj-docker-managerbackend:funds-redpacket-rest:8092
instance_ID_2=dev-ggzj-docker-redpacke:funds-redpacket-rest:8092
ins_dir=/data/funds-redpacket
pkg_name=funds-redpacket-rest.jar
##---------------------------------------------
function shutdown(){
		##offically shutdown application through API, return body MUST be upperletter "SUCCESS" or "FAIL"
		##,return code MUST be "200" if Application has been successfully been shutdown, Exception
		##code was predefined below.
		return_body="SUCCESS"
		res=$(curl -XPOST -H "Content-Type: application/json" -d '{"user":"admin","password":"123456"}' http://$1)
		if [[ $res == $return_body ]];then
			echo $res
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
        ssh root@$1 "docker stop funds-redpacket-rest"
		scp /data/docker/${pkg_name} root@$1:$ins_dir
		ssh root@$1 "docker start funds-redpacket-rest"
}

function backup(){
		##streamline and standardise package name
		scp $WORKSPACE/funds-redpacket-rest/target/funds-redpacket-rest-*-SNAPSHOT.jar /data/docker/$pkg_name
}

function Log_Print(){
		##Printing startup logs as deploy phase finished.
       	ssh root@$1 "cd $ins_dir && tail -n 50 server.log"
}

function SuccessPrint(){
		Project="Funds"
		ModuleName="redpacket"
		echo $Project $ModuleName "$@" "[Succeed!]"
}

function FailedPrint(){
		Project="Funds"
		ModuleName="redpacket"
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

