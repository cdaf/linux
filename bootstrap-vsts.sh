#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

scriptName='bootstrap-vsts.sh'
echo "[$scriptName] --- start ---"
url="$1"
if [ -z "$url" ]; then
	echo "url not passed, HALT!"
	exit 101
else
	echo "[$scriptName]   url            : $url"
fi

pat="$2"
if [ -z "$pat" ]; then
	echo "pat not passed, HALT!"
	exit 102
else
	echo "[$scriptName]   pat            : $pat"
fi

pool="$3"
if [ -z "$pool" ]; then
	pool='Default'
	echo "[$scriptName]   pool           : $pool (default)"
else
	echo "[$scriptName]   pool           : $pool"
fi

agentName="$4"
if [ -z "$agentName" ]; then
	agentName=$(hostname)
	echo "[$scriptName]   agentName      : $agentName (default)"
else
	echo "[$scriptName]   agentName      : $agentName"
fi

echo
echo "[$scriptName] Download CDAF"
executeExpression "curl -O https://codeload.github.com/cdaf/linux/zip/master"
executeExpression "unzip master"
executeExpression "chmod -R +x ./linux-master"
executeExpression "cd ./linux-master/"

echo
echo "[$scriptName] Create agent user and register"
executeExpression "./automation/provisioning/addUser.sh vstsagent vstsagent yes" # VSTS Agent with sudoer access
executeExpression "./automation/provisioning/installAgent.sh $url \$pat $pool $agentName"

echo "[$scriptName] --- end ---"
