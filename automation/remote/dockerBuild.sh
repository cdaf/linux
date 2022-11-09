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

scriptName='dockerBuild.sh'

echo; echo "[$scriptName] Build docker image, resulting image tag will be ${imageName}:${tag}"; echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not supplied, exit with code 1."
	exit 1
else
	imageName=$(echo "$imageName" | tr '[:upper:]' '[:lower:]')
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
	if [ ! -z "$tag" ]; then
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

echo; echo "[$scriptName] List existing images..."
executeExpression "docker images -f label=cdaf.${imageName}.image.version"

echo "[$scriptName] As of 1.13.0 new prune commands, if using older version, suppress error"
executeSuppress "docker system prune -f"

buildCommand='docker build --progress plain'

if [ ! -z "$tag" ]; then
	buildCommand+=" --build-arg BUILD_TAG=${tag}"
fi

if [ "$rebuild" == 'yes' ]; then
	buildCommand+=" --no-cache=true"
fi

if [ ! -z "$userName" ]; then
	buildCommand+=" --build-arg userName=$userName"
fi

if [ ! -z "$userID" ]; then
	buildCommand+=" --build-arg userID=$userID"
fi

if [ ! -z "$tag" ]; then
	buildCommand+=" --tag ${imageName}:${tag}"
else
	buildCommand+=" --tag ${imageName}"
fi

if [ ! -z "$CONTAINER_IMAGE" ]; then
	echo; echo "[$scriptName] \$CONTAINER_IMAGE is set (${CONTAINER_IMAGE}), pass as \$CONTAINER_IMAGE to build"
	buildCommand+=" --build-arg CONTAINER_IMAGE=${CONTAINER_IMAGE}"
fi

for envVar in $(env | grep CDAF_IB_); do
	envVar=$(echo ${envVar//CDAF_IB_})
	buildCommand+=" --build-arg ${envVar}"
done

if [ "$version" != 'dockerfile' ]; then
	# Apply required label for CDAF image management
	buildCommand+=" --label=cdaf.${imageName}.image.version=${version}"
fi

echo
export PROGRESS_NO_TRUNC='1'
executeExpression "$buildCommand ."

echo; echo "[$scriptName] List Resulting images..."
executeExpression "docker images -f label=cdaf.${imageName}.image.version"

echo; echo "[$scriptName] --- end ---"
