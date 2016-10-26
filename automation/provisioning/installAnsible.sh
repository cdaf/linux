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

scriptName='installAnsible.sh'

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

options=$1
if [ -z "$1" ]; then
	echo "[$scriptName]   options      : Not supplied, will use default"
else
	echo "[$scriptName]   options      : $options"
fi

if [ "$centos" ]; then # Fedora

	echo "[$scriptName] TODO: Fedora not implemented."

else # Debian

	executeExpression "sudo apt-get install software-properties-common"
	executeExpression "sudo apt-add-repository ppa:ansible/ansible -y"
	executeExpression "sudo apt-get update -y"
	executeExpression "sudo apt-get install -y ansible"

fi

echo "[$scriptName] List version details..."
executeExpression "python${version} --version"
 
echo "[$scriptName] --- end ---"
