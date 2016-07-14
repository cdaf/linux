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

scriptName='dockerImage.sh'
echo
echo "[$scriptName] Tag an image with the environment it is to be used in."
echo
echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	imageName='prefix'
	echo "[$scriptName] imageName   : ${imageName} (default)"
else
	imageName=$1
	echo "[$scriptName] imageName   : ${imageName}"
fi

if [ -z "$2" ]; then
	environment='latest'
	echo "[$scriptName] environment : ${environment} (default)"
else
	environment=$2
	echo "[$scriptName] environment : ${environment}"
fi

echo "[$scriptName] Tag image  ${imageName}_image as ${imageName}_image:${environment}"

executeExpression "docker tag -f ${imageName}_image ${imageName}_image:${environment}"

echo "List available images for logging purposes."

docker images

echo "[$scriptName] --- end ---"
