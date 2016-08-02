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
echo "[$scriptName] Create an instance from an image ID, based on build."
echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not supplied! Exit with code 1."
	exit 1
else
	echo "[$scriptName] imageName   : ${imageName}"
fi

branch=$2
if [ -z "$branch" ]; then
	echo "[$scriptName] branch not supplied! Exit with code 2."
	exit 2
else
	echo "[$scriptName] branch      : ${branch}"
fi

buildNumber=$3
if [ -z "$buildNumber" ]; then
	echo "[$scriptName] buildNumber not supplied! Exit with code 3."
	exit 3
else
	echo "[$scriptName] buildNumber : ${buildNumber}"
fi

dockerExpose=$4
if [ -z "$dockerExpose" ]; then
	echo "[$scriptName] dockerExpose not passed, exiting with code 4."
	exit 4
else
	echo "[$scriptName] dockerExpose    : $dockerExpose"
fi

publishedPort=$5
if [ -z "$publishedPort" ]; then
	publishedPort='80'
	echo "[$scriptName] publishedPort   : $publishedPort (default)"
else
	echo "[$scriptName] publishedPort   : $publishedPort"
fi

for id in $(docker images -f label=cdaf.${imageName}.image.build=${branch}:${buildNumber} -q); do
	if [ -z "$uniqueID" ]; do
		$uniqueID = $id
	else
		if [ "$uniqueID" != "$id" ]; then
			echo "[$scriptName] build (${build}) did not return a unique ID! Exit with code 99."
			exit 99
		fi
	fi
done

# Globally unique label, based on port, if in use, stop and remove
instance="${branch}:${publishedPort}"
echo "[$scriptName] instance        : $instance (container ID)"

echo
echo "List the running containers (before)"
docker ps

# Test is based on combination of image name and port to force exit if the port is in use by another image 
for containerInstance in $(docker ps --filter label=cdaf.${imageName}.container.instance=${instance} -q); do
	echo "[$scriptName] Stop and remove existing container instance ($instance)"
	executeExpression "docker stop $containerInstance"
	executeExpression "docker rm $containerInstance"
done

echo
# Labels, other than instance, are for filter purposes, only instance is important in run context. 
executeExpression "docker run -d -p ${publishedPort}:${dockerExpose} --name $name --label cdaf.${imageName}.container.instance=$instance --label cdaf.${imageName}.container.environment=$environment $uniqueID"

echo
echo "List the running containers (after)"
docker ps

echo "[$scriptName] --- end ---"
