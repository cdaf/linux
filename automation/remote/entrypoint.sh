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

scriptName='entryPoint.sh'
echo "[$scriptName] --- start ---"
buildNumber=$1
if [ -z "$buildNumber" ]; then
	echo "[$scriptName] buildNumber  : (not supplied)"
else
	echo "[$scriptName] buildNumber  : $buildNumber"
fi

executeExpression "cd /workspace"

if [ -n $buildNumber ]; then
	executeExpression "./automation/processor/buildPackage.sh $buildNumber"
else
	executeExpression "./automation/cdEmulate.sh buildonly"
fi

echo
echo "[$scriptName] --- end ---"
