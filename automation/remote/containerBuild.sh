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

scriptName='containerBuild.sh'
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not supplied, exit with code 1."
	exit 1
else
	echo "[$scriptName] imageName    : $imageName"
fi

buildNumber=$2
if [ -z "$buildNumber" ]; then
	echo "[$scriptName] buildNumber  : (not supplied)"
else
	echo "[$scriptName] buildNumber  : $buildNumber"
fi

command=$3
if [ -z "$command" ]; then
	echo "[$scriptName] command      : (not passed, please set label in Dockerfile cdaf.${imageName}.image.command)"
else
	echo "[$scriptName] command      : $command"
fi

rebuildImage=$4
if [ -z "$rebuildImage" ]; then
	echo "[$scriptName] rebuildImage : (not supplied)"
else
	echo "[$scriptName] rebuildImage : $rebuildImage"
fi

echo "[$scriptName] \$DOCKER_HOST : $DOCKER_HOST"

# Test Docker is running
echo "[$scriptName] List all current images"
executeExpression "docker images"

buildCommand='docker build'
if [ "$rebuild" == 'yes' ]; then
	buildCommand+=" --no-cache=true"
fi

if [ -n "$tag" ]; then
	buildCommand+=" --tag ${imageName}:${tag}"
else
	buildCommand+=" --tag ${imageName}"
fi

for imageTag in $(docker images --filter label=cdaf.${imageName}.image.version --format "{{.Tag}}"); do
	echo "imageTag : $imageTag"
done
newTag=$((${imageTag} + 1))
echo "newTag   : $newTag"

executeExpression "cat Dockerfile"

if [ "$rebuildImage" == "yes" ]; then
	executeExpression "automation/remote/dockerBuild.sh ${imageName} $newTag $newTag yes"
else
	executeExpression "automation/remote/dockerBuild.sh ${imageName} $newTag"
fi

# Remove any older images	
executeExpression "automation/remote/dockerClean.sh ${imageName} $newTag"

# Retrieve the latest image number
for imageTag in $(docker images --filter label=cdaf.${imageName}.image.version --format "{{.Tag}}"); do
	echo "imageTag : $imageTag"
done

workspace=$(pwd)
echo "[$scriptName] \$imageTag  : $imageTag"
echo "[$scriptName] \$workspace : $workspace"

command="automation/remote/entrypoint.sh $buildNumber"

if [ -n "$command" ]; then
	executeExpression "docker run --tty --volume ${workspace}:/workspace ${imageName}:${imageTag} $command"
else
	executeExpression "docker run --tty --volume ${workspace}:/workspace ${imageName}:${imageTag}"
fi

echo "[$scriptName] List and remove all stopped containers"
executeExpression 'docker ps --filter "status=exited" -a'
executeExpression 'docker rm $(docker ps --filter "status=exited" -aq)'

echo
echo "[$scriptName] --- end ---"
