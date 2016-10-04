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

password=$3

# If the group does not exist, create it
groupExists=$(getent group $groupname)
if [ "$groupExists" ]; then
	echo "[$scriptName] groupname $groupname exists"
else
	executeExpression "sudo groupadd $groupname"
fi

userExists=$(id -u $username 2> /dev/null )
if [ -z "$userExists" ]; then # User does not exist, create the user in the group
	if [ "$centos" ]; then
		executeExpression "sudo adduser -g $groupname $username"
	else
		executeExpression "sudo adduser --disabled-password --gecos \"\" --ingroup $groupname $username"
	fi
else # Just add the user to the group
	echo "[$scriptName] username $username exists"
	executeExpression "sudo usermod -a -G $groupname $username"
fi

if [ -n "$password" ]
then
    # We cannot use the executeExpression function here beacuse this will print out the password to stdout, which we
    # want to avoid. So we have to replicate its functionality.
    len=${#password} 
    passmask=`perl -e "print '*' x $len;"`

    cmdreal="echo \"$username:$password\" | sudo chpasswd"
    cmdmask="echo \"$username:$passmask\" | sudo chpasswd"

    echo "[$scriptName] $cmdmask"
    eval $cmdreal

    # Check execution normal, anything other than 0 is an exception
    if [ "$exitCode" != "0" ]; then
        echo "$0 : Exception! $cmdmask returned $exitCode"
        exit $exitCode
    fi
fi

echo "[$scriptName] --- end ---"
