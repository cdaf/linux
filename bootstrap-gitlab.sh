#!/usr/bin/env bash

# Minimum argument or environment variable is the runner token
# export GITLAB_TOKEN=xxxxxx
# curl -s https://raw.githubusercontent.com/cdaf/linux/master/bootstrap-gitlab.sh | bash -

# If using an on-premise agent, can set GITHUB_URL, or pass arguments
# curl -O https://raw.githubusercontent.com/cdaf/linux/master/bootstrap-gitlab.sh
# chmod +x bootstrap-gitlab.sh
# ./bootstrap-gitlab.sh xxxxxx https://on.premise

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
if [ -z "$GITLAB_TOKEN" ]; then
	GITLAB_TOKEN="$1"
	if [ -z "$GITLAB_TOKEN" ]; then
		echo "GITLAB_TOKEN not passed and environment variable not set, HALT!"
		exit 102
	else
		echo "[$scriptName]   GITLAB_TOKEN : \$GITLAB_TOKEN"
	fi
else
	echo "[$scriptName]   GITLAB_TOKEN : \$GITLAB_TOKEN"
fi

if [ -z "$GITLAB_URL" ]; then
	GITLAB_URL="$2"
	if [ -z "$GITLAB_URL" ]; then
		GITLAB_URL='https://gitlab.com'
		echo "[$scriptName]   GITLAB_URL   : $GITLAB_URL (Default)"
	else
		echo "[$scriptName]   GITLAB_URL   : $GITLAB_URL"
	fi
else
	echo "[$scriptName]   GITLAB_URL   : $GITLAB_URL (using environment variable)"
fi

executor="$3"
if [ -z "$executor" ]; then
	echo "[$scriptName]   executor     : (not supplied, default will be used)"
else
	echo "[$scriptName]   executor     : $executor"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami       : $(whoami)"
else
	echo "[$scriptName]   whoami       : $(whoami) (elevation not required)"
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

executeExpression "$elevate ./automation/provisioning/installRunner.sh $GITLAB_URL \$GITLAB_TOKEN $executor"

echo "[$scriptName] --- end ---"
