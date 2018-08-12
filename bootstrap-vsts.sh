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

stable="$5"
if [ -z "$stable" ]; then
	stable='no'
	echo "[$scriptName]   stable         : $stable (not supplied, set to default)"
else
	echo "[$scriptName]   stable         : $stable"
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

# Default is to use the latest from GitHub
if [[ stable == 'no' ]]; then
	if [ -d 'linux-master' ]; then
		executeExpression "rm -rf linux-master"
	fi
	executeExpression "curl -s https://codeload.github.com/cdaf/linux/zip/master --output linux-master.zip"
	executeExpression "unzip linux-master.zip"
	executeExpression "cd linux-master/"
else
	executeExpression "curl -s -O http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
	executeExpression "tar -xzf LU-CDAF.tar.gz"
fi

echo; echo "[$scriptName] Create agent user and register"
executeExpression "$elevate ./automation/provisioning/addUser.sh vstsagent vstsagent yes" # VSTS Agent with sudoer access
executeExpression "./automation/provisioning/base.sh curl" # ensure curl is installed, this will also ensure apt-get is unlocked
executeExpression "./automation/provisioning/installAgent.sh $url \$pat $pool $agentName"

echo "[$scriptName] --- end ---"
