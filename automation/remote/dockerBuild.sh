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

scriptName='dockerBuild.sh'
echo
echo "[$scriptName] Build docker image, resulting image naming \${imageName}"
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
	echo "[$scriptName] version   : (not passed, please set label in Dockerfile cdaf.${imageName}.image.version)"
else
	echo "[$scriptName] version   : $version"
fi

rebuild=$4
if [ -z "$rebuild" ]; then
	echo "[$scriptName] rebuild   : (not supplied)"
else
	echo "[$scriptName] rebuild   : $rebuild"
fi

buildCommand='docker build'
if [ "$rebuild" == 'yes' ]; then
	buildCommand+=" --no-cache=true"
fi

if [ -n "$tag" ]; then
	buildCommand+=" --tag ${imageName}:${tag}"
else
	buildCommand+=" --tag ${imageName}"
fi

if [ -n "$version" ]; then
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
