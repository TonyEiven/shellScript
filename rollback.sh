#!/bin/bash
##---------------------------------------------
##应用地址数组定义
ACCOUNT_REST_ADDR=()
ACTIVITY_REST_ADDR=()
BALANCE_REST_ADDR=()
BILL_REST_ADDR=()
CLOCK_REST_ADDR=()
MESSAGE_REST_ADDR=()
SCORE_REST_ADDR=()
##应用实例ID数组定义
ACCOUNT_REST_ID=(prod_funds_score_account1:funds-account-rest:8080 prod_funds_score_account2:funds-account-rest:8080)
ACTIVITY_REST_ID=(prod-funds-score-clock1:funds-activity-rest:8081 prod-funds-score-clock2:funds-activity-rest:8081)
BALANCE_REST_ID=(prod_funds_score_balance1:funds-balance-rest:8080 prod_funds_score_balance2:funds-balance-rest:8080)
BILL_REST_ID=(prod_funds_score_bill1:funds-bill-rest:8080 prod_funds_score_bill2:funds-bill-rest:8080)
CLOCK_REST_ID=(prod-funds-score-signin-activity1:funds-clock-rest:8080 prod-funds-score-signin-activity2:funds-clock-rest:8080)
MESSAGE_REST_ID=(prod-funds-score-message1:funds-message-rest:8080 prod-funds-score-message2:funds-message-rest:8080)
SCORE_REST_ID=(prod_funds_score_rest1:funds-score-rest:8080 prod_funds_score_rest2:funds-score-rest:8080)
##应用包名定义
ACCOUNT_REST_PKG=rest-funds-account.jar
ACTIVITY_REST_PKG=rest-funds-activity.jar
BALANCE_REST_PKG=rest-funds-balance.jar
BILL_REST_PKG=rest-funds-bill.jar
CLOCK_REST_PKG=funds-clock-rest.jar
MESSAGE_REST_PKG=funds-message-rest.jar
SCORE_REST_PKG=funds-score-rest.jar
##应用名数组
APP_NAME=(
FUNDS-ACCOUNT-REST
FUNDS-ACTIVITY-REST
FUNDS-BALANCE-REST
FUNDS-BILL-REST
FUNDS-CLOCK-REST
FUNDS-MESSAGE-REST
FUNDS-SCORE-REST)
##---------------------------------------------
##定义基础变量
DATE=$(date +%Y-%m-%d)
USER=
PASSWD=
EUREKA_API=http://ipaddress:3000/eureka/apps/
KEY=
LOCAL_DIR=

##---------------------------------------------
##公共函数
function mark_down(){
		curl -u $USER:$PASSWD $EUREKA_API$1/status?value=DOWN -X PUT
}
function shutdown(){
		##offically shutdown application through API, return body MUST be upperletter "SUCCESS" or "FAIL"
		##,return code MUST be "200" if Application has been successfully been shutdown, Exception
		##code was predefined below.
		return_body="SUCCESS"
		res=$(curl -XPOST -H "Content-Type: application/json" -d '{"user":"","password":""}' http://$1)
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
		ADDR=$1   # remote host ip address
		INSID=$2  # instance id
		RPKG=$3   # remote host pkg name, dirname SHOULD be included.
        ssh -i $KEY root@$ADDR "cd $3 && ./spring.sh stop"
		scp -i $KEY $LOCAL_DIR$RollBackPkg root@$ADDR:$RPKG
        mark_down $INSID
        waitime 10
		ssh -i $KEY root@$ADDR "cd $3 && ./spring.sh start"
}
function ins_deploy_func(){
		##Instance Deployment,
		##deployment MUST include at least 3 phase, shutdown-->sleep-->AppKilled
		ADDR=$1   # remote host ip address   
		RPKG=$2   # remote host pkg name, dirname SHOULD be included.
		shutdown "$1:8080/offline"   # OFFLINE application through API
		waitime 10
        ssh -i $KEY root@$ADDR "cd $2 && ./spring.sh stop"
		scp -i $KEY $LOCAL_DIR$RollBackPkg root@$ADDR:$RPKG
		ssh -i $KEY root@$ADDR "cd $2 && ./spring.sh start"
}
function Log_Print(){
       	ssh -i $KEY root@$1 "cd $2 && tail -n 50 server.log"
}

function Log_Succeed_Print(){
		echo "$@" "[Succeed!]"
}

function Log_Failed_Print(){
		echo "$@" "[Failed!]"
}

function start_print(){
		echo "Starting to RollingBack $RollBackPkg" 
}

##---------------------------------------------
##回滚函数
function rollingback(){
		ADDR=$1     # remote host ip address 
		RPKG=$2     # remote host pkg name, dirname SHOULD be included.
		INSID=$3    # instance id
		APP_NAME=$4 # application's name
		INS_DIR=/data/$RPKG # standardize package name
		start_print # print started logs
		ins_deploy_func $ADDR $INS_DIR
		waitime 60
		statu=$(curl -u ${USER}:${PASSWD} -H "Content-Type: application/json" -H "Accept: application/json" ${EUREKA_API}${APP_NAME}/$INSID | jq '.instance|.status')
		if [[ $statu == \"UP\" ]];then
			Log_Succeed_Print "Funds module ${RollBackPkg} RollingBack"
		elif [[ $statu == \"DOWN\" ]];then
			Log_Failed_Print "Funds module ${RollBackPkg} $ADDR RollingBack"
			Log_Print $ADDR
			exit 1
		else
			echo "UNKOWN STATUS ${status}"
    		Log_Print $ADDR
			exit 2
		fi
}

function rollingback_pred(){
		ADDR=$1
		INSID=$2
		APP_NAME=FUNDS-ACCOUNT-REST
        INS_DIR=/data/$ACCOUNT_REST_PKG
        start_print
        ins_deploy $ADDR $2 $INS_DIR
		waitime 60
		statu=`curl -u ${USER}:${PASSWD} -H "Content-Type: application/json" -H "Accept: application/json" ${EUREKA_API}${APP_NAME}/$2 | jq '.instance|.status'`
		if [[ $statu == \"UP\" ]];then
			Log_Succeed_Print "Funds module ${RollBackPkg} RollingBack"
		elif [[ $statu == \"DOWN\" ]];then
			Log_Failed_Print "Funds module ${RollBackPkg} $ADDR RollingBack"
			Log_Print $ADDR $INS_DIR
    		exit 1
		else
			echo "UNKOWN STATUS ${status}"
    		Log_Print $ADDR $INS_DIR
    		exit 2
		fi   
}

function rollingback_ad(){
		ADDR=$1     # remote host ip address 
		RPKG=$2     # remote host pkg name, dirname SHOULD be included.
		INSID=$3    # instance id
		APP_NAME=$4 # application's name
		BASE=$5
		INS_DIR=/data/$5/$RPKG # standardize package name
		start_print # print started logs
		ins_deploy_func $ADDR $INS_DIR
		waitime 60
		statu=$(curl -u ${USER}:${PASSWD} -H "Content-Type: application/json" -H "Accept: application/json" ${EUREKA_API}${APP_NAME}/$INSID | jq '.instance|.status')
		if [[ $statu == \"UP\" ]];then
			Log_Succeed_Print "Funds module ${RollBackPkg} RollingBack"
		elif [[ $statu == \"DOWN\" ]];then
			Log_Failed_Print "Funds module ${RollBackPkg} $ADDR RollingBack"
			Log_Print $ADDR
			exit 1
		else
			echo "UNKOWN STATUS ${status}"
    		Log_Print $ADDR
			exit 2
		fi
}



##---------------------------------------------
##判断回滚应用名
if [[ $RollBackPkg == *rest-funds-account* ]];then
	rollingback ${ACCOUNT_REST_ADDR[0]} $ACCOUNT_REST_PKG ${ACCOUNT_REST_ID[0]} ${APP_NAME[0]}
    rollingback ${ACCOUNT_REST_ADDR[1]} $ACCOUNT_REST_PKG ${ACCOUNT_REST_ID[1]} ${APP_NAME[0]}
elif [[ $RollBackPkg == *rest-funds-activity* ]];then
	rollingback ${ACTIVITY_REST_ADDR[0]} $ACTIVITY_REST_PKG ${ACTIVITY_REST_ID[0]} ${APP_NAME[1]} activity
    rollingback ${ACTIVITY_REST_ADDR[1]} $ACTIVITY_REST_PKG ${ACTIVITY_REST_ID[1]} ${APP_NAME[1]} activity
elif [[ $RollBackPkg == *rest-funds-balance* ]];then
	rollingback ${BALANCE_REST_ADDR[0]} $BALANCE_REST_PKG ${BALANCE_REST_ID[0]} ${APP_NAME[2]}
    rollingback ${BALANCE_REST_ADDR[1]} $BALANCE_REST_PKG ${BALANCE_REST_ID[1]} ${APP_NAME[2]}
elif [[ $RollBackPkg == *rest-funds-bill* ]];then
	rollingback ${BILL_REST_ADDR[0]} $BILL_REST_PKG ${BILL_REST_ID[0]} ${APP_NAME[3]}
    rollingback ${BILL_REST_ADDR[1]} $BILL_REST_PKG ${BILL_REST_ID[1]} ${APP_NAME[3]}
elif [[ $RollBackPkg == *funds-clock-rest* ]];then
	rollingback ${CLOCK_REST_ADDR[0]} $CLOCK_REST_PKG ${CLOCK_REST_ID[0]} ${APP_NAME[4]} clock
    rollingback ${CLOCK_REST_ADDR[1]} $CLOCK_REST_PKG ${CLOCK_REST_ID[1]} ${APP_NAME[4]} clock
elif [[ $RollBackPkg == *funds-message-rest* ]];then
	rollingback ${MESSAGE_REST_ADDR[0]} $SCORE_REST_PKG ${MESSAGE_REST_ID[0]} ${APP_NAME[5]}
    rollingback ${MESSAGE_REST_ADDR[1]} $SCORE_REST_PKG ${MESSAGE_REST_ID[1]} ${APP_NAME[5]}
elif [[ $RollBackPkg == *funds-score-rest* ]];then
	rollingback ${SCORE_REST_ADDR[0]} $MESSAGE_REST_PKG ${SCORE_REST_ID[0]} ${APP_NAME[6]}
    rollingback ${SCORE_REST_ADDR[1]} $MESSAGE_REST_PKG ${SCORE_REST_ID[1]} ${APP_NAME[6]}
else
	echo "Couldn't find this funds package~"
fi
