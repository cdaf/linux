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

scriptName='installPIPModule.sh'

echo "[$scriptName] --- start ---"
modules=$1
if [ -z "$modules" ]; then
	echo "[$scriptName] Module(s) not supplied, exit code with code 1"; exit 1
else
	echo "[$scriptName]   modules   : $modules"
fi

vitualEnv=$2
if [ -z "$vitualEnv" ]; then
	echo "[$scriptName]   vitualEnv : (not supplied, will attempt system wide)"
else
	echo "[$scriptName]   vitualEnv : $vitualEnv"
fi

if [ -z "$vitualEnv" ]; then

	executeExpression "sudo pip install ${modules}"

else
	
	executeExpression "source /usr/local/bin/virtualenvwrapper.sh"
	executeExpression "cd $vitualEnv"
	executeExpression "workon $(workon)"
	executeExpression "pip install ${modules}"

fi
 
echo "[$scriptName] --- end ---"
