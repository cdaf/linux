#!/usr/bin/env bash

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

scriptName='installnodemon.sh'
echo
echo "[$scriptName] nodemon, Process Manager for Node.js"
echo

echo "[$scriptName] sudo npm install -g nodemon"
sudo sh -c 'for startScript in $(find /etc/profile.d -type f -name *.sh); do . $startScript ;echo $startScript; done; npm -version; npm install -g nodemon'

executeRetry "nodemon --version"

echo "[$scriptName] --- end ---"
