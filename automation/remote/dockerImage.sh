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

scriptName='dockerImage.sh'
echo
echo "[$scriptName] Tag an image"
echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	imageName='prefix'
	echo "[$scriptName] imageName   : ${imageName} (default)"
else
	echo "[$scriptName] imageName   : ${imageName}"
fi

tag=$2
if [ -z "$tag" ]; then
	tag='latest'
	echo "[$scriptName] tag : ${tag} (default)"
else
	echo "[$scriptName] tag : ${tag}"
fi


echo
echo "[$scriptName] List images (before)"
executeExpression "docker images"

echo "[$scriptName] Tag image"

executeExpression "docker tag -f ${imageName} ${imageName}:${tag}"

echo
echo "[$scriptName] List images (after)"
executeExpression "docker images"

echo "[$scriptName] --- end ---"
