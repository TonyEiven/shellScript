#!/bin/bash
#Author: tony
#Description: Manipulate Jenkins through RESTful API
#Defining some rudimentary variables.

WORKSPACE=/data
if [ ! -d $WORKSPACE ];then
	mkdir -f $WORKSPACE
	cd $WORKSPACE
fi
LENGTH=`cat $WORKSPACE/Job | wc -l`
JOBSNAME=`cat $WORKSPACE/Job`
JOBSURL=`cat $WORKSPACE/Url`

#Declare two arrays to store jobname and joburl
declare -a arr_jobname
declare -a arr_joburl
declare USER
declare PWD
declare JenkinsURL
declare ViewName
declare Jobs

#Round-robin JOBSNAME & JOBSURL, stored each line to jobname array` joburl array.
i=0
for jobname in $JOBSNAME
do
	arr_jobname[$i]=$jobname
	i=`expr $i + 1`
	if [ $i -eq $LENGTH ]
	then
		break 2
	fi
done
j=0
for joburl in $JOBSURL
do
	arr_joburl[$j]=$joburl
	j=`expr $j + 1`
	if [ $j -eq $LENGTH ]
	then
		break 3
	fi
done

#Parse URL, get all of the job and it's url
function Geturl(){
	curl -u ${USER}:${PWD} -XGET ${JenkinsURL}/api/json | jq '.jobs[] | .url' | tr -d '"' > $WORKSPACE/Url
	curl -u ${USER}:${PWD} -XGET ${JenkinsURL}/api/json | jq '.jobs[] | .name' | tr -d '"' > $WORKSPACE/Job
}

#Download XML configuration file.
function DownLoadXML(){
	for ((i=0;i<=$LENGTH;i++))
	do
		curl -u ${USER}:${PWD} -XGET ${arr_joburl[$i]} > $WORKSPACE/${arr_jobname[$i]}.xml
	done
}
#Migrate Jobs by using XML configuration file stored in working directory, Using Post Method.
function MigrateJob(){
	for ((i=0;i<=$LENGTH;i++))
	do
		curl -u ${USER}:${PWD} -X POST --data-binary "@$WORKSPACE/${arr_jobname[$i]}.xml" --header "Content-type: application/xml" ${JenkinsURL}/createItem?name=${arr_jobname[$i]}
	done
}
#Create Job by using xml configuration file stored in working directory, Using Post Method.
function CreateJob(){
	for ((i=0;i<=$LENGTH;i++))
	do
		curl -u ${USER}:${PWD} -X POST --data-binary "@${arr_jobname[$i]}.xml" --header "Content-type: application/xml" ${JenkinsURL}/createItem?name=${arr_jobname[$i]}
	done
}
#Create View by using XML configuration file stored in working directory, Using Post Method.

function CreateView(){
	for ((i=0;i<=$LENGTH;i++))
	do
		curl -u ${USER}:${PWD} -X POST --data-binary "@view.xml" --header "Content-type: application/xml" ${JenkinsURL}/createView?name=${ViewName}
	done
}

while getopts ":u:p:mv:j:l:" ARG
do
	case $ARG in
		u)
			USER=$OPTARG
			;;
		p)
			PWD=$OPTARG
			;;
		m)
			
			;;
		v)
			ViewName=$OPTARG
			;;
		j)
			Jobs=$OPTARG
			;;
		l)
			JenkinsURL=$OPTARG
			;;
		h|--help)
			echo ""
			echo ""
			echo ""
			echo ""
			echo ""
			echo ""
			echo ""
			echo ""
			;;
		*)
			echo "Usage: $0 -u|-p|-m|-v|-j"
			exit 1
	esac
done


