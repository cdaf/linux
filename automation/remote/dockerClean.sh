#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName]   $1"
	eval $1
	# There is no exception handling as new host will return errors when removing non existing containers.
}  

scriptName='cleanImage.sh'
echo
echo "[$scriptName] This script will trap exceptions and proceed normally when an image does not exist."
echo
echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	image='app'
	echo "[$scriptName] image  : $image (default)"
else
	image=$1
	echo "[$scriptName] image  : $image"
fi

if [ -z "$2" ]; then
	tag='latest'
	echo "[$scriptName] tag    : $tag (default)"
else
	tag=$2
	echo "[$scriptName] tag    : $tag"
fi
echo "[$scriptName] whoami : $(whoami)"
echo "[$scriptName] host   : $(hostname)"
echo
echo "[$scriptName] Stop and remove ${image}_instance and ${image}_container"
executeExpression "docker stop ${image}_instance 2>/dev/null"
executeExpression "docker rm ${image}_instance 2>/dev/null"
executeExpression "docker rmi ${image}_container 2>/dev/null"
echo
if [ "$tag" != 'latest' ]; then
	echo "[$scriptName] Stop and remove ${image}_instance_${tag} and ${image}_container:${tag}"
	executeExpression "docker stop ${image}_instance_${tag} 2>/dev/null"
	executeExpression "docker rm ${image}_instance_${tag} 2>/dev/null"
	executeExpression "docker rmi ${image}_container:_${tag} 2>/dev/null"
fi
echo
echo "[$scriptName] Purge Untagged containers"
for image in $(docker images | grep "^<none>" | awk '{print $3}'); do
	executeExpression "docker rmi $image"
done
echo
echo "[$scriptName] List available images"
executeExpression "docker images"
echo
echo "[$scriptName] List containers, docker ps"
executeExpression "docker ps"

echo "[$scriptName] --- end ---"
