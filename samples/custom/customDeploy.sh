#!/usr/bin/env bash

scriptName='customDeploy.sh'

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

function executeRetry {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval "$1"
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		else
			success='yes'
		fi
	done
} 

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
