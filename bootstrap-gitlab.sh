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

scriptName='bootstrap-gitlab.sh'
echo "[$scriptName] --- start ---"
url="$1"
if [ -z "$url" ]; then
	echo "url not passed, HALT!"
	exit 101
else
	echo "[$scriptName]   url      : $url"
fi

pat="$2"
if [ -z "$pat" ]; then
	echo "pat not passed, HALT!"
	exit 102
else
	echo "[$scriptName]   pat      : \$pat"
fi

executor="$3"
if [ -z "$executor" ]; then
	echo "[$scriptName]   executor : (not supplied, default will be used)"
else
	echo "[$scriptName]   executor : $executor"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami         : $(whoami)"
else
	echo "[$scriptName]   whoami         : $(whoami) (elevation not required)"
fi
echo

# First check for CDAF in current directory, then check for a Vagrant VM, if not Vagrant
if [ -d './automation' ]; then
	echo "[$scriptName] ./automation exists, assuming this contains CDAF..."
else
	echo "[$scriptName] ./automation does not exist, download CDAF..."
	executeExpression "curl -s https://raw.githubusercontent.com/cdaf/linux/master/install.sh | bash -"
fi

echo; echo "[$scriptName] Create agent user and register"
executeExpression "$elevate ./automation/provisioning/addUser.sh vstsagent vstsagent yes" # VSTS Agent with sudoer access
executeExpression "$elevate ./automation/provisioning/base.sh curl" # ensure curl is installed, this will also ensure apt-get is unlocked

executeExpression "$elevate ./automation/provisioning/installRunner.sh $url \$pat $executor"

echo "[$scriptName] --- end ---"
