#!/usr/bin/env bash

# Minimum argument or environment variable is the runner token
# export VSTS_URL=https://dev.azure.com/my-organisation
# export VSTS_TOKEN=xxxxxx
# curl -s https://raw.githubusercontent.com/cdaf/linux/master/bootstrap-vsts.sh | bash -

# If using an on-premise agent, can set GITHUB_URL, or pass arguments
# curl -O https://raw.githubusercontent.com/cdaf/linux/master/bootstrap-vsts.sh
# chmod +x bootstrap-vsts.sh
# ./bootstrap-vsts.sh https://on.premise xxxxxx

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
	if [ -z "$VSTS_URL" ]; then
	VSTS_URL="$1"
	if [ -z "$VSTS_URL" ]; then
		echo "VSTS_URL not passed, HALT!"
		exit 101
	else
		echo "[$scriptName]   VSTS_URL  : $VSTS_URL"
	fi
else
	echo "[$scriptName]   VSTS_URL  : $VSTS_URL (using environment variable)"
fi

if [ -z "$VSTS_TOKEN" ]; then
	VSTS_TOKEN="$2"
	if [ -z "$VSTS_TOKEN" ]; then
		echo "VSTS_TOKEN not passed, HALT!"
		exit 102
	else
		echo "[$scriptName]   VSTS_TOKEN : \$VSTS_TOKEN"
	fi
else
	echo "[$scriptName]   VSTS_TOKEN : \$VSTS_TOKEN (using environment variable)"
fi

pool="$3"
if [ -z "$pool" ]; then
	echo "[$scriptName]   pool       : (not supplied)"
else
	echo "[$scriptName]   pool       : $pool"
fi

agentName="$4"
if [ -z "$agentName" ]; then
	echo "[$scriptName]   agentName  : (not supplied)"
else
	echo "[$scriptName]   agentName  : $agentName"
fi

stable="$5"
if [ -z "$stable" ]; then
	stable='no'
	echo "[$scriptName]   stable     : $stable (not supplied, set to default, i.e. use latest from GitHub)"
else
	echo "[$scriptName]   stable     : $stable"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
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

executeExpression "$elevate ./automation/provisioning/installAgent.sh $VSTS_URL \$VSTS_TOKEN $pool $agentName"

executeExpression "$elevate ./automation/provisioning/installDocker.sh"

echo "Restart to apply permissions"
executeExpression "$elevate shutdown -r now"

echo "[$scriptName] --- end ---"
