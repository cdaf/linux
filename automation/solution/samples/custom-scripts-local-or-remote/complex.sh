#!/usr/bin/env bash
SOLUTION="$1"
BUILDNUMBER="$2"
TARGET="$3"

function executeExpression {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval $1
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

scriptName='complex.sh'

echo "[$scriptName] --- start ---"
echo "[$scriptName]  SOLUTION    : $SOLUTION"
echo "[$scriptName]  BUILDNUMBER : $BUILDNUMBER"
echo "[$scriptName]  TARGET      : $TARGET"
echo

loadProperties="propertiesForLocalTasks/$TARGET"	
echo "$0 : PROPFILE : $loadProperties"
propertiesList=$(./transform.sh "$loadProperties")
printf "$propertiesList"
eval $propertiesList

echo "custom script testing compatible commands:"
echo whoami

echo "Argument 1 is :"
echo $1

echo "[$scriptName] --- stop ---"
