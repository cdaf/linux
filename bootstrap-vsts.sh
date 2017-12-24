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

executeExpression "./automation/provisioning/installDocker.sh"         # Docker and Compose
executeExpression "./automation/provisioning/installOracleJava.sh jdk" # Docker and Compose

echo "[$scriptName] --- end ---"
