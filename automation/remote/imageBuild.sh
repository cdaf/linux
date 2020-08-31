#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='imageBuild.sh'

echo; echo "[$scriptName] --- start ---"
id=$1
echo "[$scriptName]  id                    : $id"

BUILDNUMBER=$2
echo "[$scriptName]  BUILDNUMBER           : $BUILDNUMBER"

containerImage=$3
if [ -z $CONTAINER_IMAGE ]; then
	if [ -z "$containerImage" ]; then
		echo "[$scriptName] Environment variable CONTAINER_IMAGE not found and containerImage argument not passed!"; exit 2715
	else
		export CONTAINER_IMAGE="$containerImage"
		echo "[$scriptName]  CONTAINER_IMAGE       : $CONTAINER_IMAGE (set to argument passed)"
	fi
else
	echo "[$scriptName]  CONTAINER_IMAGE       : $CONTAINER_IMAGE (not changed as already set)"
fi

constructor=$4
if [ -z "$constructor" ]; then
	echo "[$scriptName]  constructor           : (not supplied, supports space separated list)"
else
	echo "[$scriptName]  constructor           : $constructor (supports space separated list)"
fi

if [ -z "$CDAF_AUTOMATION_ROOT" ]; then
	CDAF_AUTOMATION_ROOT='../automation'
	echo "[$scriptName]  CDAF_AUTOMATION_ROOT  : $CDAF_AUTOMATION_ROOT (not set, using relative path)"
else
	echo "[$scriptName]  CDAF_AUTOMATION_ROOT  : $CDAF_AUTOMATION_ROOT"
fi

workspace=$(pwd)
echo "[$scriptName]  pwd                   : $workspace"

echo "Create the image file system locally"
if [ ! -d "/tmp/buildImage/${id}" ]; then
	executeExpression "mkdir -p /tmp/buildImage/${id}"
fi

if [ -z "$constructor" ]; then
	constructor=$(find . -mindepth 1 -maxdepth 1 -type d)
fi

for image in $constructor; do

	echo; echo "------------------------"
	echo "   ${image##*/}"
	echo "------------------------"; echo
	executeExpression "rm -rf /tmp/buildImage/${id}/**"
	if [ -f "../dockerBuild.sh" ]; then
		executeExpression "cp ../dockerBuild.sh /tmp/buildImage/${id}"
	else
		executeExpression "cp $CDAF_AUTOMATION_ROOT/remote/dockerBuild.sh /tmp/buildImage/${id}"
	fi
	if [ -f "../dockerClean.sh" ]; then
		executeExpression "cp ../dockerClean.sh /tmp/buildImage/${id}"
	else
		executeExpression "cp $CDAF_AUTOMATION_ROOT/remote/dockerClean.sh /tmp/buildImage/${id}"
	fi
	executeExpression "cp -r $CDAF_AUTOMATION_ROOT /tmp/buildImage/${id}"
	executeExpression "cp -r ${image}/** /tmp/buildImage/${id}"
	executeExpression "cd /tmp/buildImage/${id}"
	executeExpression "cat Dockerfile"
    image=$(echo "$image" | tr '[:upper:]' '[:lower:]')
	executeExpression "./dockerBuild.sh ${id}_${image##*/} $BUILDNUMBER $BUILDNUMBER no $(whoami) $(id -u)"
	executeExpression "./dockerClean.sh ${id}_${image##*/} $BUILDNUMBER"
	executeExpression "cd $workspace"

done

echo "[$scriptName] --- stop ---"
