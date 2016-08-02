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
	executeExpression "docker tag -f ${imageName} ${imageName}:${tag}"
fi

echo "[$scriptName] List Resulting images. Note: label is derived from Dockerfile"
executeExpression "docker images -f label=cdaf.${imageName}.image.product=${imageName}"
echo
echo "[$scriptName] --- end ---"
