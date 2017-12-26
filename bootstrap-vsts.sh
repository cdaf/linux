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
	echo "[$scriptName]   pat            : \$pat"
fi

pool="$3"
if [ -z "$pool" ]; then
	echo "[$scriptName]   pool           : (not supplied)"
else
	echo "[$scriptName]   pool           : $pool"
fi

agentName="$4"
if [ -z "$agentName" ]; then
	echo "[$scriptName]   agentName      : (not supplied)"
else
	echo "[$scriptName]   agentName      : $agentName"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami         : $(whoami)"
else
	echo "[$scriptName]   whoami         : $(whoami) (elevation not required)"
fi

echo
echo "[$scriptName] Download CDAF"
if [ -d './automation' ]; then
	executeExpression "rm -rf './automation'"
fi
if [ -d './Readme.md' ]; then
	executeExpression "rm -f './Readme.md'"
fi
if [ -d './Vagrantfile' ]; then
	executeExpression "rm -f './Vagrantfile'"
fi
executeExpression "curl -s -O http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
executeExpression "tar -xzf LU-CDAF.tar.gz"

echo
echo "[$scriptName] Create agent user and register"
executeExpression "$elevate ./automation/provisioning/addUser.sh vstsagent vstsagent yes" # VSTS Agent with sudoer access
executeExpression "./automation/provisioning/installAgent.sh $url \$pat $pool $agentName"

echo "[$scriptName] --- end ---"
