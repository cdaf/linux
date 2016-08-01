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

scriptName='dockerRun.sh'
echo
echo "[$scriptName] This script will trap exceptions and proceed normally when an image does not exist."
echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not passed, exiting with code 1."
	exit 1
else
	echo "[$scriptName] imageName       : $imageName"
fi

dockerExpose=$2
if [ -z "$dockerExpose" ]; then
	echo "[$scriptName] dockerExpose not passed, exiting with code 2."
	exit 2
else
	echo "[$scriptName] dockerExpose    : $dockerExpose"
fi

publishedPort=$3
if [ -z "$publishedPort" ]; then
	publishedPort='80'
	echo "[$scriptName] publishedPort   : $publishedPort (default)"
else
	echo "[$scriptName] publishedPort   : $publishedPort"
fi

tag=$4
if [ -z "$tag" ]; then
	tag='latest'
	echo "[$scriptName] tag             : $tag (default)"
else
	echo "[$scriptName] tag             : $tag"
fi

environment=$5
if [ -z "$environment" ]; then
	environment=$tag
	echo "[$scriptName] environment     : $environment (not passed, set to same value as tag)"
else
	echo "[$scriptName] environment     : $environment"
fi

# Because a single host can support multiple products, for environment to be unique on the host, prepend with product name
envUnique="${imageName}.${environment}"
echo "[$scriptName] envUnique       : $envUnique"
echo
echo "List the running containers (before)"
docker ps

# Globally unique label, based on port, if in use, stop and remove
instance="${imageName}_${publishedPort}"
for containerInstance in $(docker ps --filter label=instance=${instance} -q); do
	echo "[$scriptName] Stop and remove existing container instance ($instance)"
	executeExpression "docker stop $containerInstance"
	executeExpression "docker rm $containerInstance"
done

echo
executeExpression "docker run -d -p ${publishedPort}:${dockerExpose} --name "$instance" --label environment="${envUnique}" ${imageName}:${tag}"

echo
echo "List the running containers (after)"
docker ps

echo
echo "[$scriptName] --- end ---"
