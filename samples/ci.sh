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

scriptName='ci.sh'
echo;echo "[$scriptName] --- start ---"
buildNumber=$1
if [ -z "$buildNumber" ]; then
	echo "[$scriptName]   buildNumber not supplied"; exit 101
else
	echo "[$scriptName]   buildNumber : $buildNumber"
fi

branchName=$2
if [ -z "$branchName" ]; then
	echo "[$scriptName]   branchName  : (no supplied)"
else
	echo "[$scriptName]   branchName  : $branchName"
fi

echo;echo "[$scriptName] execute all code blocks in the readme"
while read LINE
do
	if [[ $LINE == '```' ]]; then
		if [[ $start == 'yes' ]]; then
			start='no'
		else
			start='yes'
		fi 
	else
		if [[ $start == 'yes' ]]; then
			executeExpression "$LINE"
		fi
	fi
	
done < readme.md

echo "[$scriptName] --- end ---"
