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
	stable='no' # I change this to no when there is a required pending change in installAgent.sh
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

# First check for CDAF in current directory, then check for a Vagrant VM, if not Vagrant
if [ -d './automation/provisioning' ]; then
	atomicPath='./automation/provisioning'
else
	echo "[$scriptName] Provisioning directory ($atomicPath) not found in workspace, looking for alternative ..."
	if [ -d '/vagrant/automation' ]; then
		atomicPath='/vagrant/automation/provisioning'
	else
		echo "[$scriptName] $atomicPath not found for Vagrant, download latest from GitHub"
		if [ -d 'linux-master' ]; then
			executeExpression "rm -rf linux-master"
		fi
		echo "[$scriptName] $atomicPath not found for Vagrant, download latest from GitHub"
		executeExpression "curl -s -O http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
		executeExpression "tar -xzf LU-CDAF.tar.gz"
		atomicPath='./automation/provisioning'
	fi
fi

echo; echo "[$scriptName] Create agent user and register"
executeExpression "$elevate ${atomicPath}/addUser.sh vstsagent vstsagent yes" # VSTS Agent with sudoer access
executeExpression "$elevate ${atomicPath}/base.sh curl" # ensure curl is installed, this will also ensure apt-get is unlocked

if [[ $stable == 'no' ]]; then # to use the unpublished installer, requires unzip to extract download from GitHub
	executeExpression "$elevate ${atomicPath}/base.sh unzip"
	if [ -d "cdaf_edge" ]; then
		executeExpression "rm -rf cdaf_edge"
	fi
	executeExpression "mkdir cdaf_edge"
	executeExpression "cd cdaf_edge"
	executeExpression "curl -s https://codeload.github.com/cdaf/linux/zip/master --output linux-master.zip"
	executeExpression "unzip linux-master.zip"
	atomicPath='./linux-master/automation/provisioning'
fi

executeExpression "$elevate ${atomicPath}/installAgent.sh $url \$pat $pool $agentName"

echo "[$scriptName] --- end ---"
