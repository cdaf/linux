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

scriptName='dockerBuild.sh'
echo
echo "[$scriptName] Build docker image based on patten \${prefix}_image"
echo
echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "[$scriptName] containerPrefix not supplied, exit with code 1."
	exit 1
else
	containerPrefix=$1
	echo "[$scriptName] containerPrefix : $containerPrefix"
fi

executeExpression "docker build -t ${containerPrefix}_image ."

echo "[$scriptName] --- end ---"
