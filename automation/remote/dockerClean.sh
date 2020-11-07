#!/usr/bin/env bash
scriptName=${0##*/}

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

function executeSuppress {
	echo "[$scriptName]   $1"
	eval $1
	# There is no exception handling as new host will return errors when removing non existing containers.
}  

echo; echo "[$scriptName] Clean image from registry based on Product label. If a tag is passed,"
echo "[$scriptName] only images with a tag value less that the one supplied and removed."
echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not supplied! Exit with code 1."
	exit 1
else
	imageName=$(echo "$imageName" | tr '[:upper:]' '[:lower:]')
	echo "[$scriptName] imageName : ${imageName}"
fi

tag=$2
if [ -z "$tag" ]; then
	echo "[$scriptName] tag not supplied, all will be removed."
else
	re='^[0-9]+$'
	if [[ ${tag} =~ $re ]] ; then # Tag is a number
		echo "[$scriptName] tag       : ${tag}"
	else
		echo "[$scriptName] tag (${tag}) is not an integer! Exit with code 2."
		exit 2
	fi
fi

echo
echo "[$scriptName] List images (before)"
executeExpression "docker images"

echo
echo "[$scriptName] Remove untagged orphaned (dangling) images"
for imageID in $(docker images -aq -f dangling=true); do
	executeSuppress "docker rmi -f $imageID"
done	

echo
echo "[$scriptName] Remove the image (ignore failures), this process relies on the following"
echo "[$scriptName] dockerfile label where @imageName@ is replaced with the product name."
echo "[$scriptName]   LABEL cdaf.@imageName@.image.version"
echo "[$scriptName]   docker images --filter label=cdaf.${imageName}.image.version -a"
echo "[$scriptName] Note: The actual image version value is ignored."
if [ -z "$tag" ]; then
	for imageID in $(docker images --filter label=cdaf.${imageName}.image.version -aq); do
		executeSuppress "docker rmi -f $imageID"
	done	
else
	# Need to read complete lines, not separation at spaces
	IFS=$'\n'
	for imageDetail in $(docker images --filter label=cdaf.${imageName}.image.version -a); do
		IFS=' '
		arr=($imageDetail)
		re='^[0-9]+$'
		if [[ ${arr[1]} =~ $re ]] ; then # Tag is an integer
			if [ "${arr[1]}" -lt "$tag" ]; then
				echo "[$scriptName] Remove Image ${arr[0]}:${arr[1]}"
				executeSuppress "docker rmi -f ${arr[2]}"
			fi
		fi
	done	
fi

echo
echo "[$scriptName] List images (after)"
executeExpression "docker images"

echo
echo "[$scriptName] --- end ---"
