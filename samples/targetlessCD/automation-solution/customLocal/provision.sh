#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][ERROR] $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  
scriptName='provision.sh'

echo "[$scriptName] --- start ---"
node="$1"
if [ -z "$node" ]; then
	echo "[$scriptName]   node    : (not supplied, default provisioning only)"
else
	echo "[$scriptName]   node    : $node"
fi

release="$2"
if [ -z "$release" ]; then
    release='edge'
	echo "[$scriptName]   release : $release (default)"
else
	echo "[$scriptName]   release : $release"
fi

export CDAF_INSTALL_PATH=/opt/cdaf
if [[ $release == 'edge' ]]; then
    executeExpression "curl -s https://raw.githubusercontent.com/cdaf/linux/master/install.sh | bash -"   # Edge
else
    executeExpression "curl -s https://cdaf.io/static/app/downloads/cdaf.sh | bash -"                     # Published
fi

executeExpression "/opt/cdaf/remote/capabilities.sh"

if [[ $node == 'ubuntu' ]]; then
    executeExpression "/opt/cdaf/provisioning/addUser.sh deployer"
    executeExpression "/opt/cdaf/provisioning/mkDirWithOwner.sh /opt/packages deployer"
    executeExpression "/opt/cdaf/provisioning/mkDirWithOwner.sh /opt/cdds deployer"
    executeExpression "/opt/cdaf/provisioning/deployer.sh target"
elif [[ $node == 'build' ]]; then
    executeExpression "/opt/cdaf/provisioning/setenv.sh CDAF_DELIVERY VAGRANT"
    executeExpression "/opt/cdaf/provisioning/deployer.sh server" # Install Insecure preshared key for desktop testing
    executeExpression "/opt/cdaf/provisioning/internalCA.sh"
fi

executeExpression "/opt/cdaf/provisioning/installNodeJS.sh 16"
executeExpression "/opt/cdaf/remote/capabilities.sh"

echo "[$scriptName] --- finish ---"
