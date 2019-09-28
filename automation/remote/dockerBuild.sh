#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$scriptName : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName=${0##*/}

echo; echo "[$scriptName] Build docker image, resulting image naming \${imageName}"
echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not supplied, exit with code 1."
	exit 1
else
	echo "[$scriptName] imageName : $imageName"
fi

tag=$2
if [ -z "$tag" ]; then
	echo "[$scriptName] tag not supplied"
else
	echo "[$scriptName] tag       : $tag"
fi

version=$3
if [ -z "$version" ]; then
	if [ -n "$tag" ]; then
		version=$tag
	    echo "[$scriptName] version   : $version (not supplied, defaulted to tag)"
	else
		version='0.0.0'
	    echo "[$scriptName] version   : $version (not supplied, and tag not passed, set to 0.0.0)"
	fi
else
	if [ "$version" == 'dockerfile' ]; then # Backward compatibility
		echo "[$scriptName] version   : $version (please set label in Dockerfile cdaf.${imageName}.image.version)"
	else
		echo "[$scriptName] version   : $version"
	fi
fi

rebuild=$4
if [ -z "$rebuild" ]; then
	echo "[$scriptName] rebuild   : (not supplied)"
else
	echo "[$scriptName] rebuild   : $rebuild"
fi

userName=$5
if [ -z "$userName" ]; then
	echo "[$scriptName] userName  : (not supplied)"
else
	echo "[$scriptName] userName  : $userName"
fi

userID=$6
if [ -z "$userID" ]; then
	echo "[$scriptName] userID    : (not supplied)"
else
	echo "[$scriptName] userID    : $userID"
fi

buildCommand='docker build'

if [ -n "$tag" ]; then
	buildCommand+=" --build-arg BUILD_TAG=${tag}"
fi

if [ "$rebuild" == 'yes' ]; then
	buildCommand+=" --no-cache=true"
fi

if [ -n "$userName" ]; then
	buildCommand+=" --build-arg userName=$userName"
fi

if [ -n "$userID" ]; then
	buildCommand+=" --build-arg userID=$userID"
fi

if [ -n "$tag" ]; then
	buildCommand+=" --tag ${imageName}:${tag}"
else
	buildCommand+=" --tag ${imageName}"
fi

if [ -n "$http_proxy" ]; then
	echo; echo "[$scriptName] \$http_proxy is set (${http_proxy}), pass as \$proxy to build"
	buildCommand+=" --build-arg proxy=${http_proxy}"
else
	if [ -n "$HTTP_PROXY" ]; then
		echo; echo "[$scriptName] \$HTTP_PROXY is set (${HTTP_PROXY}), pass as \$proxy to build"
		buildCommand+=" --build-arg proxy=${HTTP_PROXY}"
	fi
fi

if [ -n "$CONTAINER_IMAGE" ]; then
	echo; echo "[$scriptName] \$CONTAINER_IMAGE is set (${CONTAINER_IMAGE}), pass as \$CONTAINER_IMAGE to build"
	buildCommand+=" --build-arg CONTAINER_IMAGE=${CONTAINER_IMAGE}"
fi

if [ "$version" != 'dockerfile' ]; then
	# Apply required label for CDAF image management
	buildCommand+=" --label=cdaf.${imageName}.image.version=${version}"
fi

echo
executeExpression "$buildCommand ."
echo
echo "[$scriptName] List Resulting images..."
executeExpression "docker images -f label=cdaf.${imageName}.image.version"
echo
echo "[$scriptName] --- end ---"
