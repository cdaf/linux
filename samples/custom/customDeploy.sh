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

scriptName='customDeploy.sh'

echo; echo "[$scriptName] --- start ---"
SOLUTION=$1
echo "[$scriptName]  SOLUTION      : $SOLUTION"
BUILDNUMBER=$2
echo "[$scriptName]  BUILDNUMBER   : $BUILDNUMBER"
DEPLOY_TARGET=$3
echo "[$scriptName]  DEPLOY_TARGET : $DEPLOY_TARGET"

propertiesList=$(./transform.sh "$DEPLOY_TARGET")
printf "$propertiesList"
eval $propertiesList

echo "custom script testing compatible commands:"
executeExpression "whoami"

echo "[$scriptName] --- stop ---"
