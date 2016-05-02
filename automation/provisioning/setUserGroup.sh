#!/usr/bin/env bash
scriptName='setUserGroup.sh'
echo
echo "[$scriptName] Add a user as a member of a group"
echo
echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	username='deployer'
	echo "[$scriptName]   username  : $username (default)"
else
	username=$1
	echo "[$scriptName]   username  : $username"
fi

if [ -z "$2" ]; then
	groupname='docker'
	echo "[$scriptName]   groupname : $groupname (default)"
else
	groupname=$2
	echo "[$scriptName]   groupname : $groupname"
fi

echo "[$scriptName] Determine distribution"
uname -a
centos=$(uname -a | grep el)

if [ -z "$centos" ]; then

	echo "[$scriptName] Ubuntu :> sudo usermod -a -G $groupname $username"
	sudo usermod -a -G $groupname $username

else

	echo "[$scriptName] CentOS :> sudo usermod -G $groupname $username"
	sudo usermod -G $groupname $username
		
fi

echo "[$scriptName] --- end ---"
