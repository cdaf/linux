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

scriptName='addUser.sh'
echo
echo "[$scriptName] Create a new user, optionally, in a predetermined group"
echo
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
	username='deployer'
	echo "[$scriptName]   username     : $username (default)"
else
	username=$1
	echo "[$scriptName]   username     : $username"
fi

if [ -z "$2" ]; then
	groupname=$1
	echo "[$scriptName]   groupname    : $groupname (defaulted to \$username)"
else
	groupname=$2
	echo "[$scriptName]   groupname    : $groupname"
fi

# If the group does not exist, create it
groupExists=$(getent group $groupname)
if [ "$groupExists" ]; then
	echo "[$scriptName] $groupname exists"
else
	executeExpression "sudo groupadd $groupname"
fi

# Create the user in the group
if [ "$centos" ]; then
	executeExpression "sudo adduser -g $groupname $username"
else
	executeExpression "sudo adduser --disabled-password --gecos \"\" --ingroup $groupname $username"
fi

echo "[$scriptName] --- end ---"
