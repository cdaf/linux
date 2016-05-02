#!/usr/bin/env bash
scriptName='addUser.sh'
echo
echo "[$scriptName] Create a new user, optionally, in a predetermined group"
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
	echo "[$scriptName]   groupname : not supplied, will use default"
else
	groupname=$2
	echo "[$scriptName]   groupname : $groupname"
	
	# If the group does not exist, create it
	groupExists=$(getent group $groupname)
	if [ -z "$groupExists" ]; then
		echo "[$scriptName] sudo groupadd $groupname"
		sudo groupadd $groupname
	fi

fi

if [ -z "$2" ]; then
	# Create the user in default group (i.e. groupname and username the same)
	if [ -z "$centos" ]; then
		echo "[$scriptName] Ubuntu/Debian : sudo adduser --disabled-password --gecos \"\" $username"
		sudo adduser --disabled-password --gecos "" $username
	else
		echo "[$scriptName] CentOS/RHEL : sudo adduser -G $groupname $username"
		sudo adduser -G $groupname $username
	fi
else
	# Create the user in the group
	if [ -z "$centos" ]; then
		echo "[$scriptName] Ubuntu/Debian : sudo adduser --disabled-password --gecos \"\" --group $groupname $username"
		sudo adduser --disabled-password --gecos "" --ingroup $groupname $username
	else
		echo "[$scriptName] CentOS/RHEL : sudo adduser -G $groupname $username"
		sudo adduser -G $groupname $username
	fi
fi

echo "[$scriptName] --- end ---"
