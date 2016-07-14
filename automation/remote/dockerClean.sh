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

scriptName='dockerClean.sh'
echo
echo "[$scriptName] This script will trap exceptions and proceed normally when an image does not exist."
echo
echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	image='prefix'
	echo "[$scriptName] image       : ${image} (default)"
else
	image=$1
	echo "[$scriptName] image       : ${image}"
fi

if [ -z "$2" ]; then
	environment='latest'
	echo "[$scriptName] environment : ${environment} (default)"
else
	environment=$2
	echo "[$scriptName] environment : ${environment}"
fi

echo
echo "[$scriptName] List all images (before)"
executeExpression "docker images --all"

echo
echo "[$scriptName] List all containers (before)"
executeExpression "docker ps --all"

echo
echo "[$scriptName] List containers based on label (environment=${environment})"
docker ps --all --filter "label=environment=${environment}"

echo
echo "[$scriptName] Stop containers based on label (environment=${environment})"
for container in $(docker ps --all --filter "label=environment=${environment}" -q); do
	executeExpression "docker stop $container"
	executeExpression "docker rm $container"
done

echo
echo "[$scriptName] Remove the image"
executeSuppress "docker rmi ${image}_image:${environment} 2>/dev/null"

echo
echo "[$scriptName] Purge Untagged containers"
for image in $(docker images | grep "^<none>" | awk '{print $3}'); do
	executeSuppress "docker rmi $image"
done

echo
echo "[$scriptName] Purge dangling images"
for dangler in $(docker images -f "dangling=true" -q); do
	executeSuppress "docker rmi ${dangler}"
done

echo
echo "[$scriptName] List all images (after)"
executeExpression "docker images --all"

echo
echo "[$scriptName] List all containers (after)"
executeExpression "docker ps --all"

echo "[$scriptName] --- end ---"
