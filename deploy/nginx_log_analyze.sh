#!/bin/bash
#description: analyse nginx log in order to ensure Source of attack...(only for passport)
#version: v1.0
#auth: by zhengxin20180504
#email: hzzxin@tairanchina.com

LOG_ANALYSE_DIR=/usr/local/weihu/passport_nginx-log-analyze.ori
ACCESS_FILE=${LOG_ANALYSE_DIR}/access_file
ACCESS_IP_FILE=${LOG_ANALYSE_DIR}/ip_file
ACCESS_URL_FILE=${LOG_ANALYSE_DIR}/url_file
ACCESS_CODE_FILE=${LOG_ANALYSE_DIR}/code_file
PER_IP_ACCESS_FILE=${LOG_ANALYSE_DIR}/per_access_file
PER_CODE_ACCESS_FILE=${LOG_ANALYSE_DIR}/per_code_access_file

##create directory
mkdir -p $LOG_ANALYSE_DIR

read -p "please input log file path: [example: /usr/local/nginx/logs/pass_80.access.log] " LOG_PATH
read -p "please input date: [example: 2018-05-04] " DATE

##判断日志文件是否存在
if [ x"${LOG_PATH}" = x"" ];then
    LOG_PATH="/usr/local/nginx/logs/pass_80.access.log"
else
    if [ ! -f ${LOG_PATH} ];then
        echo "sorry,access_log file not exists..."
        exit 1
    fi
fi

##判断日期是否有效
if [ x"${DATE}" = x"" ];then
    DATE=$(date +%F)
fi
 
##截取指定时间段日志并保存到临时文件中
CUT_LOG() {
    ##输入日志起始时间
    read -p "please input start time: [example: 09]: " START_TIME
    read -p "please input end time: [example: 18]: " END_TIME

    ##判断输入时间是否正确
    for i in "${START_TIME}" "${END_TIME}";do
        if ! echo {00..23} | grep -o "\<${i}\>" &>/dev/null;then
            echo "please input correct timestamps..."
            exit 1
        fi
    done

    ##截取日志并保存到临时文件
    LOG_START_TIME=$(date -d "${DATE} ${START_TIME}" +%d/%b/%Y:%H:%M:%S)
    LOG_END_TIME=$(date -d "${DATE} ${END_TIME}:59:59" +%d/%b/%Y:%H:%M:%S)
    #LOG_START_TIME=$(date -d "${DATE} ${START_TIME}" +%d/%b/%Y:%H:%M:%S)
    #LOG_END_TIME=$(date -d "${DATE} ${END_TIME}" +%d/%b/%Y:%H:%M:%S)
    awk -F '[' '$2>="'"${LOG_START_TIME}"'" && $2<="'"${LOG_END_TIME}"'"' $LOG_PATH >$ACCESS_FILE      
}

##统计并显示访问量最大的前20个ip
RECORD_IP() {
    ACCESS_INFO=$(sed -nr "s#(.*)(sourceAddress=.*)(dstAddress.*)#\2#gp" $1 | awk -F'=' '{count[$2]++} END{for(ip in count) print count[ip],ip}' | sort -rn -k 1 | head -20)

    ##将截取出来的ip保存到文件中
    echo "$ACCESS_INFO" | awk '{print $NF}' >$ACCESS_IP_FILE
    echo -e "\n\033[32;49;1m${DATE}: ip_address top 20: \033[0m"
    echo "$ACCESS_INFO" | column -t       
}

##统计并显示访问量最大的前20个url
RECORD_URL() {
    URL_INFO=$(grep -o "requestRInfo.*" $1 | awk '{count[$2]++} END{for(url in count) print count[url],url}' | sort -rn -k 1 | head -20)
 
    ##将截取出来的url保存到文件中
    echo "$URL_INFO" | awk '{print $NF}' >$ACCESS_URL_FILE   
    echo -e "\n\033[34;49;1m${DATE}: url top 20: \033[0m"
    echo "$URL_INFO" | column -t
}

##统计并显示http请求状态码信息
RECORD_HTTP_CODE() {
    CODE_INFO=$(grep -oE "responseCode=[0-5]{3}" $1 | awk -F'=' '{count[$2]++} END{for(code in count) print count[code],code}' | sort -rn -k 1)
    
    ##将截取出来的http code保存到文件中
    echo "$CODE_INFO" | awk '{print $NF}' >$ACCESS_CODE_FILE
    echo -e "\n\033[36;49;1m${DATE}: http code info: \033[0m"
    echo "$CODE_INFO" | column -t
}

##统计并显示每个ip访问详细情况(ip_address top 20)
RECORD_PER_IP_INFO (){
    echo -e "\n\033[33;49;1m${DATE}: top 20 ip的访问日志详情: \033[0m\n"
    for j in $(cat $ACCESS_IP_FILE);do
        grep "sourceAddress=${j}" $1 >$PER_IP_ACCESS_FILE
        PER_URL_INFO=$(grep -o "requestRInfo.*" $PER_IP_ACCESS_FILE | awk '{count[$2]++} END{for(url in count) print count[url],url}' | sort -rn -k 1 | head -10)
        PER_CODE_INFO=$(grep -oE "responseCode=[0-5]{3}" $PER_IP_ACCESS_FILE | awk -F'=' '{count[$2]++} END{for(code in count) print count[code],code}' | sort -rn -k 1)
        PER_REQUEST_METHOD_INFO=$(grep -o "requestRInfo.*" $PER_IP_ACCESS_FILE | awk -F'[=" ]+' '{count[$2]++} END{for(request_method in count) print count[request_method],request_method}' | sort -rn -k 1)
        echo -e "\033[31;49;1m++++++++++++++ ${j} 访问日志分析结果如下 +++++++++++++++\033[0m"
	echo -e "访问url top 10: "
        echo -e "${PER_URL_INFO}" | column -t
        echo -e "http请求方法统计: "
        echo -e "${PER_REQUEST_METHOD_INFO}" | column -t
        echo -e "http请求状态码统计: "
        echo -e "${PER_CODE_INFO}" | column -t
        sleep 1
        echo
    done
}   

##统计每种http code请求对应的最大10个url接口
RECORD_PER_CODE_INFO() {
    echo -e "\n\033[34;49;1m${DATE}: 每种http code请求日志详情: \033[0m\n"
    for i in $(cat $ACCESS_CODE_FILE);do
        grep "responseCode=${i}" $1 >$PER_CODE_ACCESS_FILE
        PER_CODE_IP_INFO=$(sed -nr "s#(.*)(sourceAddress=.*)(dstAddress.*)#\2#gp" $PER_CODE_ACCESS_FILE | awk -F'=' '{count[$2]++} END{for(ip in count) print count[ip],ip}' | sort -rn -k 1 | head -10)
        PER_CODE_URL_INFO=$(grep -o "requestRInfo.*" $PER_CODE_ACCESS_FILE | awk '{count[$2]++} END{for(url in count) print count[url],url}' | sort -rn -k 1 | head -10)
        echo -e "\033[36;49;1m++++++++++++++ http_code(${i}) 日志分析结果如下 +++++++++++++++\033[0m"
        echo -e "请求状态码为${i},top 10 ip: "
	echo -e "$PER_CODE_IP_INFO" | column -t
        echo -e "请求状态码为${i},top 10 url: "
        echo -e "$PER_CODE_URL_INFO" | column -t
    done        
}

##统计访问量(uv和pv)
RECORD_ACCESS_VISITS() {
    PV=$(wc -l $1 | awk '{print $1}')
    UV=$(sed -nr "s#(.*)(sourceAddress=.*)(dstAddress.*)#\2#gp" $1 | awk -F'=' '{count[$2]++} END{for(ip in count) print count[ip],ip}' | wc -l)
    echo -e "\n\033[33;49;1m访问量统计结果如下:\033[0m \nPV: ${PV}\nUV: ${UV}"
}


##选择菜单
MENU() {
    clear
    echo -e "++++++++++++++下沙金融用户中心nginx日志分析菜单++++++++++++++"
    echo
    echo -e "\033[33;49;1m1.[All day]\033[0m\n"
    echo -e "\033[34;49;1m2.[Period time]\033[0m"
    echo
    echo -e "++++++++++++++下沙金融用户中心nginx日志分析菜单++++++++++++++"
}

##打印更新菜单
MENU
echo
sleep 1

##主程序
read -p "please input your choice: " CHOICE

case $CHOICE in
1)
    ACCESS_LOG="$LOG_PATH"
    RECORD_IP "$ACCESS_LOG"
    RECORD_URL "$ACCESS_LOG"
    RECORD_HTTP_CODE "$ACCESS_LOG"
    RECORD_PER_IP_INFO "$ACCESS_LOG"
    RECORD_PER_CODE_INFO "$ACCESS_LOG"
    RECORD_ACCESS_VISITS "$ACCESS_LOG"
    ;;
2)
    CUT_LOG
    ACCESS_LOG="$ACCESS_FILE"
    RECORD_IP "$ACCESS_LOG"
    RECORD_URL "$ACCESS_LOG"
    RECORD_HTTP_CODE "$ACCESS_LOG"
    RECORD_PER_IP_INFO "$ACCESS_LOG"
    RECORD_PER_CODE_INFO "$ACCESS_LOG"
    RECORD_ACCESS_VISITS "$ACCESS_LOG"
    ;;
*)
    echo "USEAGE: $0 { 1 | 2 }..."
    exit 1
    ;;
esac
