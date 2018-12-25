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

scriptName='runner.sh'

echo "[$scriptName] --- start ---"

echo "[$scriptName] Working directory is $(pwd). Deploy domain and app"; echo

executeExpression "cp health-smoke-tests-*.zip /opt/mule/apps"
executeExpression "cp integration-domain-*.zip /opt/mule/domains/integration-domain.zip"

echo; echo "[$scriptName] Start mule and watch logs to keep container alive ..."; echo

executeExpression "cat /opt/mule/conf/wrapper.conf"

executeExpression "/opt/mule/bin/mule start"
executeExpression "/opt/mule/bin/mule status"

echo;echo "tail -1000f /opt/mule/logs/mule_ee.log";echo
tail -1000f /opt/mule/logs/mule_ee.log
