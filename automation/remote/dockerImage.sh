#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName]   $1"
	eval $1
	# There is no exception handling as new host will return errors when removing non existing containers.
}  

scriptName='dockerImage.sh'
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
	environment='DEV'
	echo "[$scriptName] environment : ${environment} (default)"
else
	environment=$2
	echo "[$scriptName] environment : ${environment}"
fi

echo
echo "[$scriptName] List all containers"
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
executeExpression "docker rmi ${image}_image:${environment} 2>/dev/null"

echo
echo "[$scriptName] Purge Untagged containers"
for image in $(docker images | grep "^<none>" | awk '{print $3}'); do
	executeExpression "docker rmi $image"
done

echo
echo "[$scriptName] Purge dangling images"
for dangler in $(docker images -f "dangling=true" -q); do
	executeExpression "docker rmi ${dangler}"
done

echo
echo "[$scriptName] List available images"
executeExpression "docker images"

echo
echo "[$scriptName] List running containers"
executeExpression "docker ps"

echo "[$scriptName] --- end ---"
