#!/usr/bin/env bash
scriptName=${0##*/}

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

echo
echo "[$scriptName] Start a container instance, if an instance (based on \"instance\") exists it is"
echo "[$scriptName] stopped and removed before starting the new instance."
echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not passed, exiting with code 1."
	exit 1
else
	imageName=$(echo "$imageName" | tr '[:upper:]' '[:lower:]')
	echo "[$scriptName] imageName       : $imageName"
fi

# 2.4.0 Centralise docker operations by supporting implicit clean function
dockerExpose=$2
if [ -z "$dockerExpose" ]; then
	echo "[$scriptName] dockerExpose    : (not supplied, will only clean running containers)"
else
	echo "[$scriptName] dockerExpose    : $dockerExpose"
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

	registry=$6
	if [ -z "$registry" ]; then
		echo "[$scriptName] registry        : not passed, use local repo"
	else
		if [ "$registry" == 'none' ]; then
			echo "[$scriptName] registry        : passed as '$registry', ignoring"
			unset registry
		else
			echo "[$scriptName] registry        : $registry"
		fi
	fi

	dockerOpt=$7
	if [ -z "$dockerOpt" ]; then
		echo "[$scriptName] dockerOpt       : not passed"
	else
		echo "[$scriptName] dockerOpt       : $dockerOpt"
	fi
fi

if [ ! -z "$dockerExpose" ]; then
	echo
	# Globally unique label, based on port, if in use, stop and remove
	instance="${imageName}:${publishedPort}"
	echo "[$scriptName] instance        : $instance (container ID)"

	# User the 3rd party naming standard (x_y)
	name="${imageName}_${publishedPort}"
	echo "[$scriptName] name            : $name"
fi

echo
executeExpression "docker --version"

echo
echo "List the running containers (before)"
docker ps

if [ -z "$dockerExpose" ]; then
	echo "[$scriptName] Remove any existing containers based on docker ps --filter label=cdaf.${imageName}.container.instance"
	for containerInstance in $(docker ps --filter label=cdaf.${imageName}.container.instance -aq); do
		echo "[$scriptName] Stop and remove existing container instance ($instance)"
		executeExpression "docker stop $containerInstance"
		executeExpression "docker rm $containerInstance"
	done
else
	echo "[$scriptName] Remove any existing containers based on docker ps --filter label=cdaf.${imageName}.container.instance=${instance}"
	for containerInstance in $(docker ps --filter label=cdaf.${imageName}.container.instance=${instance} -aq); do
		echo "[$scriptName] Stop and remove existing container instance ($instance)"
		executeExpression "docker stop $containerInstance"
		executeExpression "docker rm $containerInstance"
	done
fi

if [ ! -z "$dockerExpose" ]; then
	echo
	# Labels, other than instance, are for filter purposes, only instance is important in run context. 
	if [ -z "$registry" ]; then
		executeExpression "docker run -d -p ${publishedPort}:${dockerExpose} --name $name $dockerOpt --label cdaf.${imageName}.container.instance=$instance --label cdaf.${imageName}.container.environment=$environment ${imageName}:${tag}"
	else
		executeExpression "docker run -d -p ${publishedPort}:${dockerExpose} --name $name $dockerOpt --label cdaf.${imageName}.container.instance=$instance --label cdaf.${imageName}.container.environment=$environment ${registry}/${imageName}:${tag}"
	fi
fi

echo
echo "List the running containers (after)"
docker ps

echo
echo "[$scriptName] --- end ---"
