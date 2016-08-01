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

function executeSuppress {
	echo "[$scriptName]   $1"
	eval $1
	# There is no exception handling as new host will return errors when removing non existing containers.
}  

scriptName='dockerClean.sh'
echo
echo "[$scriptName] Clean image from registry based on Product label. If a tag is passed,"
echo "[$scriptName] only images with a tag value less that the one supplied and removed."
echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not supplied! Exit with code 1."
	exit 1
else
	echo "[$scriptName] imageName : ${imageName}"
fi

tag=$2
if [ -z "$tag" ]; then
	echo "[$scriptName] tag not supplied, all will be removed."
else
	echo "[$scriptName] tag       : ${tag}"
fi

echo
echo "[$scriptName] List images (before)"
executeExpression "docker images"

echo
echo "[$scriptName] Remove the image (ignore failures)"
if [ -z "$tag" ]; then
	for imageID in $(docker images --filter label=product=${imageName} -aq); do
		executeSuppress "docker rmi $imageID"
	done	
else
	# Need to read complete lines, not separation at spaces
	IFS=$'\n'
	for imageDetail in $(docker images --filter label=product=${imageName} -a); do
		IFS=' '
		arr=($imageDetail)
		if [[ "${arr[1]}" != 'TAG' ]]; then
			if [[ "${arr[1]}" < "$tag" ]]; then
				echo "[$scriptName] Remove Image ${arr[0]}:${arr[1]}"
				executeSuppress "docker rmi ${arr[2]}"
			fi
		fi
	done	
fi

echo
echo "[$scriptName] Purge dangling images, those in use will remain unaffected."
for dangler in $(docker images -f "dangling=true" -q); do
	executeSuppress "docker rmi ${dangler}"
done

echo
echo "[$scriptName] List images (after)"
executeExpression "docker images"

echo "[$scriptName] --- end ---"
