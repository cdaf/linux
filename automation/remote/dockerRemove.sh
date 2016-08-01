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
# Because a single host can support multiple products, for environment to be unique on the host, prepend with product name
envUnique="${containerPrefix}.${environment}"
echo "[$scriptName] envUnique       : $envUnique"

echo
echo "[$scriptName] List running containers (before)"
executeExpression "docker ps"

echo
echo "[$scriptName] Stop and remove containers based on label (environment=${envUnique})"
for container in $(docker ps --all --filter "label=environment=${envUnique}" -q); do
	executeExpression "docker stop $container"
	executeExpression "docker rm $container"
done

echo
echo "[$scriptName] List running containers (after)"
executeExpression "docker ps"

echo "[$scriptName] --- end ---"
