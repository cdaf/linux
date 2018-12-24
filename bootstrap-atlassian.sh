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

scriptName='bootstrap-atlassian.sh'
echo "[$scriptName] --- start ---"
prefix="$1"
if [ -z "$prefix" ]; then
	echo "[$scriptName]   password : blank"
else
	echo "[$scriptName]   password : ****************"
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
		echo "[$scriptName] $atomicPath not found for Vagrant, download stable release from cdaf.io"
		executeExpression "curl -s -O http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
		executeExpression "tar -xzf LU-CDAF.tar.gz"
		atomicPath='./automation/provisioning'
	fi
fi

echo; echo "[$scriptName] Install PostGreSQL"

executeExpression "$elevate ${atomicPath}/installPostGreSQL.sh $password"

echo "[$scriptName] --- end ---"
