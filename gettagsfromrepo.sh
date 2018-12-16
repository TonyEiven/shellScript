#!/bin/bash

# Author: Tonyeiven
# Description: Get images list from repository

function command_exist(){
	command -v "$@" > /dev/null 2>1&
}

if ! command_exist jq; then
	yum -y install epel-release
	yum -y install jq
fi

URI=$1
PORT=$2

function request(){
	local link="http://"$URI":"$PORT"/v2/_catalog"
	imagelist=$(/usr/bin/curl -XGET -s $link | jq .repositories[])
	for im in $imagelist; do
		delimi=$(echo $im| tr -d '"')
		local taglink="http://"$URI":"$PORT"/v2/$delimi/tags/list"
		tag=$(/usr/bin/curl -XGET -s $taglink | jq .tags[])
		echo -e "\033[32m $im ----> tag: $tag \033[0m"
	done
}


if [[ $# = 0 ]] || [[ "$1" == "help" ]]; then
	echo -e "\033[32m Usage: $0 uri port, i.e: $0 10.200.1.1 5000 \033[0m"
fi

request
