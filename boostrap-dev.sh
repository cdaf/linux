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

scriptName='boostrap-dev.sh'
echo "[$scriptName] --- start ---"
registryPort=$1
if [ -z "$registryPort" ]; then
	registryPort='80'
	echo "[$scriptName]   registryPort : $registryPort (default)"
else
	echo "[$scriptName]   registryPort : $registryPort"
fi

initialImage=$2
if [ -z "$initialImage" ]; then
	echo "[$scriptName]   initialImage not supplied"
else
	echo "[$scriptName]   initialImage : $initialImage"
fi

if [ -d './linux-master' ]; then
	executeExpression "rm -if './linux-master'"
fi

executeExpression "curl -O https://codeload.github.com/cdaf/linux/zip/master"
executeExpression "unzip master"
executeExpression "cd ./linux-master/"
executeExpression "for script in $(find . -name "*.sh"); do git add $script; chmod -R +x $script; git update-index --chmod=+x $script; done"
executeExpression "./automation/provisioning/base.sh 'virtualbox vagrant'"
executeExpression "./automation/provisioning/installDocker.sh" # Docker and Compose
executeExpression "./automation/provisioning/installOracleJava.sh jdk" # Docker and Compose

echo "[$scriptName] --- end ---"
