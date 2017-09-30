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

scriptName='setNoPassSUDO.sh'
echo
echo "[$scriptName] Set a user to have sudo access without password prompt"
echo
echo "[$scriptName] --- start ---"

username=$1
if [ -z "$username" ]; then
	username='deployer'
	echo "[$scriptName]   username     : $username (default)"
else
	echo "[$scriptName]   username     : $username"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami       : $(whoami)"
else
	echo "[$scriptName]   whoami       : $(whoami) (elevation not required)"
fi

executeExpression '$elevate sh -c "echo \"$username ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers"'
executeExpression "$elevate cat /etc/sudoers"

echo "[$scriptName] --- end ---"
