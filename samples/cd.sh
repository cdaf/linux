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

scriptName='cd.sh'
echo;echo "[$scriptName] Configure bamboo using cd.sh \${bamboo.deploy.environment} \${bamboo.deploy.release}"
echo;echo "[$scriptName] --- start ---"
environment=$1
if [ -z "$environment" ]; then
	echo "[$scriptName]   environment not supplied"; exit 101
else
	echo "[$scriptName]   environment : $environment"
fi

release=$2
if [ -z "$release" ]; then
	echo "[$scriptName]   release     : (no supplied)"
else
	echo "[$scriptName]   release     : $release"
fi

executeExpression "hostname"
executeExpression "whoami"

echo "[$scriptName] --- end ---"
