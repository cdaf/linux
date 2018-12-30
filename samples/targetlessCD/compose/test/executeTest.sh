#!/usr/bin/env bash
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

scriptName='executeTests.sh'

echo "[$scriptName] ---------- start ----------"
ENVIRONMENT="$1"
if [ -z "$ENVIRONMENT" ]; then
	echo "[$scriptName] ENVIRONMENT not passed, exit 101"; exit 101
else
	echo "[$scriptName]   ENVIRONMENT : $ENVIRONMENT"
fi

executeExpression "./TasksLocal/delivery.sh $ENVIRONMENT"

echo "[$scriptName] Automated Test Execution Completed Successfully."

echo; echo "[$scriptName] ---------- end ----------"

