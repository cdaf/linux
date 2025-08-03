#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
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
test=$(yum --version 2>&1)
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName]   Debian based : $(uname -mrs)"
else
	echo "[$scriptName]   Fedora based : $(uname -mrs)"
fi

username=$1
if [ -z "$username" ]; then
	username='deployer'
	echo "[$scriptName]   username     : $username (default)"
else
	echo "[$scriptName]   username     : $username"
fi

groupname=$2
if [ -z "$groupname" ]; then
	groupname=$username
	echo "[$scriptName]   groupname    : $groupname (defaulted to \$username)"
else
	echo "[$scriptName]   groupname    : $groupname"
fi

sudoer=$3
if [ -z "$sudoer" ]; then
	echo "[$scriptName]   sudoer       : (not supplied)"
else
	echo "[$scriptName]   sudoer       : $sudoer"
fi

password=$4
if [ -z "$password" ]; then
	echo "[$scriptName]   password     : (not supplied)"
else
	echo "[$scriptName]   password     : *********************"
fi

if [ "$(whoami)" != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami       : $(whoami)"
else
	echo "[$scriptName]   whoami       : $(whoami) (elevation not required)"
fi

# If the group does not exist, create it
groupExists=$(getent group $groupname)
if [ "$groupExists" ]; then
	echo "[$scriptName] groupname $groupname exists"
else
	executeExpression "$elevate groupadd $groupname"
fi

userExists=$(id -u $username 2> /dev/null )
if [ -z "$userExists" ]; then # User does not exist, create the user in the group
	if [[ "$test" == *"not found"* ]]; then
		executeExpression "$elevate useradd -m -k /dev/null -s /usr/sbin/nologin -c '' $username -G $groupname"
	else
		executeExpression "$elevate adduser -g $groupname $username"
	fi
else # Just add the user to the group
	echo "[$scriptName] username $username exists"
	executeExpression "$elevate usermod -a -G $groupname $username"
fi

if [ "$username" != "$groupname" ]; then
	echo "[$scriptName] Ensure user has group permission"
	executeExpression "$elevate gpasswd -a $username $groupname"
fi

if [ ! -z "$password" ]
then
    # We cannot use the executeExpression function here because this will print out the password to stdout, which we
    # want to avoid. So we have to replicate its functionality.
    len=${#password} 
    passmask=$(perl -e "print '*' x $len;")

    cmdreal="echo \"$username:$password\" | $elevate chpasswd"
    cmdmask="echo \"$username:$passmask\" | $elevate chpasswd"

    echo "[$scriptName] $cmdmask"
    eval "$cmdreal"

    # Check execution normal, anything other than 0 is an exception
    if [ "$exitCode" != "0" ]; then
        echo "$0 : Exception! $cmdmask returned $exitCode"
        exit $exitCode
    fi
fi

if [ ! -z "$sudoer" ]; then
	executeExpression '$elevate sh -c "echo \"$username ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers"'
	executeExpression "$elevate cat /etc/sudoers"
fi

echo "[$scriptName] --- end ---"
