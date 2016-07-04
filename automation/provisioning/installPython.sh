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

scriptName='installPython.sh'

echo "[$scriptName] --- start ---"
centos=$(uname -mrs | grep .el)
if [ "$centos" ]; then
	echo "[$scriptName]   Fedora based : $(uname -mrs)"
else
	ubuntu=$(uname -a | grep ubuntu)
	if [ "$ubuntu" ]; then
		echo "[$scriptName]   Debian based : $(uname -mrs)"
	else
		echo "[$scriptName]   $(uname -a), proceeding assuming Debian based..."; echo
	fi
fi

if [ -z "$1" ]; then
	version='3'
	echo "[$scriptName]   version     : $version (default)"
else
	version=$1
	echo "[$scriptName]   version     : $version (choices 2 or 3)"
fi

if [ "$centos" ]; then # Fedora

	executeExpression "sudo yum install -y epel-release"
	executeExpression "sudo yum install -y python${version}*"
	executeExpression "curl https://bootstrap.pypa.io/get-pip.py | sudo python3"
	executeExpression "sudo pip install virtualenv"

else # Debian

	executeExpression "sudo apt-get install -y python${version}*"

fi

echo "[$scriptName] List version details..."
executeExpression "python${version} --version"
 
echo "[$scriptName] --- end ---"
