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
if [ -z "$1" ]; then
	echo "[$scriptName] containerPrefix not passed, exiting with code 1."
	exit 1
else
	containerPrefix=$1
	echo "[$scriptName] containerPrefix : $containerPrefix"
fi

if [ -z "$2" ]; then
	echo "[$scriptName] dockerExpose not passed, exiting with code 2."
	exit 2
else
	dockerExpose=$2
	echo "[$scriptName] dockerExpose    : $dockerExpose"
fi

if [ -z "$3" ]; then
	publishedPort='80'
	echo "[$scriptName] publishedPort   : $publishedPort (default)"
else
	publishedPort=$3
	echo "[$scriptName] publishedPort   : $publishedPort"
fi

if [ -z "$4" ]; then
	environment='latest'
	echo "[$scriptName] environment     : $environment (default)"
else
	environment=$4
	echo "[$scriptName] environment     : $environment"
fi
echo
echo "List the running containers for environment ${environment} (before)"
docker ps --filter label=environment=${environment}

echo
executeExpression "docker run -d -p ${publishedPort}:${dockerExpose} --name ${containerPrefix}_instance_${publishedPort} --label environment=${environment} ${containerPrefix}_image:${environment}"

echo
echo "List the running containers for environment ${environment} (after)"
docker ps --filter label=environment=${environment}

echo
echo "[$scriptName] --- end ---"
