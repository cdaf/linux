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

function executeIgnore {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Warning! $EXECUTABLESCRIPT returned $exitCode"
	fi
}

scriptName='addDockerRegistry.sh'
echo "[$scriptName] --- start ---"
registryPort=$1
if [ -z "$registryPort" ]; then
	registryPort='80'
	echo "[$scriptName]   registryPort : $registryPort (default)"
else
	echo "[$scriptName]   registryPort : $registryPort"
fi

initialImage=$2
if [ -z "$initialImage" ]; then
	echo "[$scriptName]   initialImage not supplied"
else
	echo "[$scriptName]   initialImage : $initialImage"
fi

echo "Install registry (version 2) ..."
executeIgnore "docker run -d -p $registryPort:5000 --restart=always --name registry registry:2"

if [ -n "$initialImage" ]; then
	echo "Pull initial image ($initialImage) ..."
	executeExpression "docker pull $initialImage && docker tag $initialImage localhost/$initialImage"

	echo "Push image ($initialImage) to registry and verify ..."
    executeExpression "docker push localhost/$initialImage"
    executeExpression "docker pull localhost/$initialImage"
fi

echo "[$scriptName] --- end ---"
