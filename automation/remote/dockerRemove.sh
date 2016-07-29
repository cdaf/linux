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

scriptName='dockerRemove.sh'
echo
echo "[$scriptName] This script stops and removes all instances based on environment tag."
echo
echo "[$scriptName] --- start ---"
containerPrefix=$1
if [ -z "$containerPrefix" ]; then
	echo "[$scriptName] containerPrefix not passed, exiting with code 1."
	exit 1
else
	echo "[$scriptName] containerPrefix : $containerPrefix"
fi

environment=$2
if [ -z "$environment" ]; then
	environment='latest'
	echo "[$scriptName] environment     : $environment (default)"
else
	echo "[$scriptName] environment     : $environment"
fi

echo
echo "[$scriptName] List running containers (before)"
executeExpression "docker ps"

echo
echo "[$scriptName] List running containers based on label (environment=${environment})"
docker ps --all --filter "label=environment=${environment}"

echo
echo "[$scriptName] Stop containers based on label (environment=${environment})"
for container in $(docker ps --all --filter "label=environment=${environment}" -q); do
	executeExpression "docker stop $container"
	executeExpression "docker rm $container"
done

echo
echo "[$scriptName] List running containers (after)"
executeExpression "docker ps"

echo "[$scriptName] --- end ---"
