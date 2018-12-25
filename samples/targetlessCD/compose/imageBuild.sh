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
echo "[$scriptName]  id             : $id"
BUILDNUMBER=$2
echo "[$scriptName]  BUILDNUMBER    : $BUILDNUMBER"
containerImage=$3
echo "[$scriptName]  containerImage : $containerImage"

workspace=$(pwd)
echo "[$scriptName]  pwd            : $workspace"

if [ -z "$containerImage" ]; then
	echo "[$scriptName] containerImage  : (not defined in $solutionRoot/CDAF.solution)"
else
	if [ -z $CONTAINER_IMAGE ]; then
		export CONTAINER_IMAGE="$containerImage"
		echo "[$scriptName] CONTAINER_IMAGE : $CONTAINER_IMAGE (set to \$containerImage)"
	else
		echo "[$scriptName] containerImage  : $containerImage"
		echo "[$scriptName] CONTAINER_IMAGE : $CONTAINER_IMAGE (not changed as already set)"
	fi
fi

echo "Create the image file system locally"
if [ -d "/tmp/buildImage" ]; then
	executeExpression "rm -rf /tmp/buildImage/**"
else
	executeExpression "mkdir -p /tmp/buildImage"
fi

server='mule'
echo; echo "------------------------"
echo "   ${server} server"
echo "------------------------"; echo
executeExpression "cp ../dockerBuild.sh /tmp/buildImage"
executeExpression "cp -r ../automation /tmp/buildImage"
executeExpression "cp ./${server}/Dockerfile /tmp/buildImage"
executeExpression "cp ./${server}/bootstrapTarget.sh /tmp/buildImage"
executeExpression "cd /tmp/buildImage"
executeExpression "cat Dockerfile"
executeExpression "./dockerBuild.sh ${id}_${server} $BUILDNUMBER"
executeExpression "cd $workspace"

server='test'
echo; echo "------------------------"
echo "   ${server} server"
echo "------------------------"; echo
executeExpression "cp ../dockerBuild.sh /tmp/buildImage"
executeExpression "cp -r ../automation /tmp/buildImage"
executeExpression "cp ./${server}/Dockerfile /tmp/buildImage"
executeExpression "cp ./${server}/bootstrapTarget.sh /tmp/buildImage"
executeExpression "cp ./${server}/executeTests.sh /tmp/buildImage"
executeExpression "cd /tmp/buildImage"

executeExpression "cat Dockerfile"
executeExpression "./dockerBuild.sh ${id}_${server} $BUILDNUMBER"
executeExpression "cd $workspace"

echo "[$scriptName] --- stop ---"
