#!/usr/bin/env bash
function executeExpression {
	counter=1
	max=3
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

scriptName='bootstrapAgent.sh'

echo; echo "[$scriptName] --- start ---"
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]  whoami : $(whoami)"
else
	echo "[$scriptName]  whoami : $(whoami) (elevation not required)"
fi
echo "[$scriptName]  pwd    : $(pwd)"

echo "[$scriptName] Add any provisioning needed here"; echo
executeExpression "./automation/remote/capabilities.sh"

echo; echo "[$scriptName] --- end ---"

