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
echo
executeExpression "docker build -t ${imageName} ."
echo

if [ -n "$tag" ]; then
	echo "[$scriptName] Tag image with value passed ($tag)"
	echo "[$scriptName] docker tag -f ${imageName} ${imageName}:${tag}"
	docker tag -f ${imageName} ${imageName}:${tag}
	if [ "$?" != "0" ]; then
		#-f flag on docker tag
		#Deprecated In Release: v1.10.0
		#Removed In Release: v1.12.0
		#To make tagging consistent across the various docker commands, the -f flag on the docker tag command is deprecated. It is not longer necessary to specify -f to move a tag from one image to another. Nor will docker generate an error if the -f flag is missing and the specified tag is already in use.
		echo "[$scriptName] docker tag -f deprecated in docker release v1.10.0, try again without -f flag."
		executeExpression "docker tag ${imageName} ${imageName}:${tag}"
	fi
fi

echo "[$scriptName] List Resulting images. Note: label is derived from Dockerfile"
executeExpression "docker images -f label=cdaf.${imageName}.image.product=${imageName}"
echo
echo "[$scriptName] --- end ---"
