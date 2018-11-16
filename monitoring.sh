#!/bin/bash
# Author: tonyeiven
# Email:  Wang_tonyeiven@gmail.com
# Description: url health check 

# uri variables needed to be montioring.
SYNC_URI="https://box.trc.com/data-sync/zhicheng/share"
ADMIN_URI="https://box.trc.com/data-admin/apiv1/captcha"
RESULTOUTPUT=/data/scripts/pkg/result

function monitoring(){
	local URI=$1
	local FREQ=$2
	local BEGINSEC=$(date +%s)
	sleep $FREQ
	ret=$(/usr/bin/curl -sL -w "%{http_code}\n" -o /dev/null $URI)
	local ENDSEC=$(date +%s)
	if [[ $ret = 200 ]];then
	   printf 'BeginTime:%d,%-3s,returncode:%d,EndTime:%d\n' $BEGINSEC "Interface return normal" $ret $ENDSEC >> $RESULTOUTPUT
	fi
	if [[ $ret != 200 ]];then
	   ENDURATION= $ENDSEC - $BEGINSEC - $FREQ
	   printf 'BeginTime:%d,%-3s,returncode:%d,EndTime:%d,AccessDurationTime:%d\n' $BEGINSEC "Interface return failed" $ret $ENDSEC $ENDURATION >> $RESULTOUTPUT
	   exit 1
	fi
}
function notify(){
	local Dingding_uri=$1
	local MSGBODY=$2
	/usr/bin/curl "${Dingding_uri}" -H 'Content-Type: application/json' -d "
	{
	   \"msgtype\":\"text\",
	    \"text\":{
		\"content\":\"$MSGBODY\"
		}
	}"	
}

while (true)
do
	monitoring $SYNC_URI 30
	if [[ $? != 0 ]];then
		notify "https://oapi.dingtalk.com/robot/send?access_token=1b49c603ebea4980551ad4a1c316de5e4be22c11c633d5856b60b7317d6c31ae" \"$SYNC_URI 接口异常\"
	fi
	monitoring $ADMIN_URI 60
	if [[ $? != 0 ]];then
                notify "https://oapi.dingtalk.com/robot/send?access_token=1b49c603ebea4980551ad4a1c316de5e4be22c11c633d5856b60b7317d6c31ae" \"$ADMIN_URI 接口异常\"
        fi
done
