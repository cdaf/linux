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

scriptName='bootstrap-vsts.sh'
echo "[$scriptName] --- start ---"
url="$1"
if [ -z "$url" ]; then
	echo "url not passed, HALT!"
	exit 101
else
	echo "[$scriptName]   url            : $url"
fi

pat="$2"
if [ -z "$pat" ]; then
	echo "pat not passed, HALT!"
	exit 102
else
	echo "[$scriptName]   pat            : \$pat"
fi

pool="$3"
if [ -z "$pool" ]; then
	echo "[$scriptName]   pool           : (not supplied)"
else
	echo "[$scriptName]   pool           : $pool"
fi

agentName="$4"
if [ -z "$agentName" ]; then
	echo "[$scriptName]   agentName      : (not supplied)"
else
	echo "[$scriptName]   agentName      : $agentName"
fi

stable="$5"
if [ -z "$stable" ]; then
	stable='no'
	echo "[$scriptName]   stable         : $stable (not supplied, set to default, i.e. use latest from GitHub)"
else
	echo "[$scriptName]   stable         : $stable"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami         : $(whoami)"
else
	echo "[$scriptName]   whoami         : $(whoami) (elevation not required)"
fi


# First check for CDAF in current directory, then check for a Vagrant VM, if not Vagrant
if [ -d './automation' ]; then
	echo "[$scriptName] ./automation exists, assuming this contains CDAF..."
else
	echo "[$scriptName] ./automation does not exist, download CDAF..."
	executeExpression "curl -s https://raw.githubusercontent.com/cdaf/linux/master/install.sh | bash -"
fi

echo; echo "[$scriptName] Create agent user and register"
executeExpression "$elevate ./automation/provisioning/addUser.sh vstsagent docker yes" # VSTS Agent with sudoer access
executeExpression "$elevate ./automation/provisioning/base.sh curl" # ensure curl is installed, this will also ensure apt-get is unlocked

executeExpression "$elevate ./automation/provisioning/installAgent.sh $url \$pat $pool $agentName"

executeExpression "$elevate ./automation/provisioning/installDocker.sh"

echo "Restart to apply permissions"
executeExpression "$elevate shutdown -r now"

echo "[$scriptName] --- end ---"
