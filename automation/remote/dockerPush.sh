#!/usr/bin/env bash

function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][ERROR] Exception! $1 returned $exitCode"
		exit $exitCode
	fi
}  

function executeSuppress {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][WARN] $1 returned $exitCode"
		exit $exitCode
	fi
}

# 2.5.2 Return SHA256 as uppercase Hexadecimal, default algorith is SHA256, but setting explicitely should this change in the future
function MASKED {
	CURRENT_IFS=$IFS
	IFS=$DEFAULT_IFS
	read -ra array <<< $(echo -n $1 | sha256sum)
	echo "${array[0]}" | tr '[:lower:]' '[:upper:]'
	IFS=$CURRENT_IFS
}

scriptName='dockerPush.sh'

echo "[$scriptName] --- start ---"
imageTag=$1
if [ -z "$imageTag" ]; then
	echo "[$scriptName] imageTag not supplied!"
	exit 2501
else
	echo "[$scriptName] imageTag        : $imageTag"
fi

registryContext=$2
if [ -z "$registryContext" ]; then
	echo "[$scriptName] registryContext not supplied!"
	exit 2501
else
	echo "[$scriptName] registryContext : $registryContext"
fi

registryTags=$3
if [ -z "$registryTags" ]; then
	echo "[$scriptName] registryTags not supplied!"
	exit 2503
else
    echo "[$scriptName] registryTags    : $registryTags (can be space separated list)"
fi

registryToken=$4
if [ -z "$registryToken" ]; then
	echo "[$scriptName] registryToken   : (not supplied, login will not be attempted)"
else
	echo "[$scriptName] registryToken   : $(MASKED $registryToken) (MASKED)"
fi

registryUser=$5
if [ -z "$registryUser" ]; then
	registryUser='.'
	echo "[$scriptName] registryUser    : $registryUser (default)"
else
	echo "[$scriptName] registryUser    : $registryUser"
fi

registryURL=$6
if [ -z "$registryURL" ]; then
	echo "[$scriptName] registryURL     : (not supplied, do not set when pushing to Dockerhub)"
else
	echo "[$scriptName] registryURL     : $registryURL"
fi

if [ $registryToken ]; then
	executeExpression "echo \$registryToken | docker login --username $registryUser --password-stdin $registryURL"
fi

if [ ! -z $registryURL ]; then
	registryContext="${registryURL}/${registryContext}"
fi

for tag in $registryTags; do
	executeExpression "docker tag ${imageTag} ${registryContext}:$tag"
	executeExpression "docker push ${registryContext}:$tag"
done

echo; echo "[$scriptName] --- end ---"
