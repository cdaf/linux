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
image=$1
if [ -z "$image" ]; then
	image='prefix'
	echo "[$scriptName] image       : ${image} (default)"
else
	echo "[$scriptName] image       : ${image}"
fi

tag=$2
if [ -z "$tag" ]; then
	tag='latest'
	echo "[$scriptName] tag : ${tag} (default)"
else
	echo "[$scriptName] tag : ${tag}"
fi

echo
echo "[$scriptName] List images (before)"
executeExpression "docker images"

echo
echo "[$scriptName] List containers (before)"
executeExpression "docker ps"

echo
echo "[$scriptName] List all containers based on label (environment=${tag})"
docker ps --all --filter "label=environment=${tag}"

echo
echo "[$scriptName] Stop containers based on label (environment=${tag})"
for container in $(docker ps --all --filter "label=environment=${tag}" -q); do
	executeExpression "docker stop $container"
	executeExpression "docker rm $container"
done

echo
echo "[$scriptName] Remove the image"
executeSuppress "docker rmi ${image}_image:${tag} 2>/dev/null"

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
echo "[$scriptName] List images (after)"
executeExpression "docker images"

echo
echo "[$scriptName] List containers (after)"
executeExpression "docker ps"

echo "[$scriptName] --- end ---"
