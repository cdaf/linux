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

scriptName='installpm2.sh'
echo
echo "[$scriptName] : Install pm2 components"
echo

# snippet from http://unix.stackexchange.com/questions/18209/detect-init-system-using-the-shell
INIT=`sudo sh -c "ls -l /proc/1/exe"`
if [[ "$INIT" == *"systemd"* ]]; then
  SYSTEMINITDAEMON=systemd
fi
if [ -z "$SYSTEMINITDAEMON" ]; then
    echo "[$scriptName] :ERROR:Startup type untested: $SYSTEMINITDAEMON"
    exit 1
fi

executeExpression "sudo npm install pm2@latest -g"
executeExpression "pm2 startup $SYSTEMINITDAEMON"

echo "[$scriptName] --- end ---"
