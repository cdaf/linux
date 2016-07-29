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

function executeSuppress {
	echo "[$scriptName]   $1"
	eval $1
	# There is no exception handling as new host will return errors when removing non existing containers.
}  

scriptName='dockerImage.sh'
echo
echo "[$scriptName] Tag an image with the environment it is to be used in and"
echo "[$scriptName] remove any untagged image, i.e. unused images from previous release."
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


echo
echo "[$scriptName] List images (before)"
executeExpression "docker images"

echo "[$scriptName] Tag image  ${imageName}_image as ${imageName}_image:${environment}"

executeExpression "docker tag -f ${imageName}_image ${imageName}_image:${environment}"

echo
echo "[$scriptName] Purge untagged containers, those in use will remain unaffected."
for image in $(docker images | grep "^<none>" | awk '{print $3}'); do
	executeSuppress "docker rmi $image 2>/dev/null"
done

echo
echo "[$scriptName] Purge dangling images, those in use will remain unaffected."
for dangler in $(docker images -f "dangling=true" -q); do
	executeSuppress "docker rmi ${dangler} 2>/dev/null"
done

echo
echo "[$scriptName] List images (after)"
executeExpression "docker images"

echo "[$scriptName] --- end ---"
