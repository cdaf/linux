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

scriptName='bootstrapAgent.sh'

echo "[$scriptName] --- start ---"
echo "[$scriptName] Working directory is $(pwd)"

if [ -d './automation' ]; then
	atomicPath='.'
else
	echo "[$scriptName] Provisioning directory ($atomicPath) not found in workspace, looking for alternative ..."
	if [ -d '/vagrant/automation' ]; then
		atomicPath='/vagrant'
	else
		echo "[$scriptName] $atomicPath not found for either Docker or Vagrant! Exit with error 34"; exit 34
	fi
fi

echo
test="`curl --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] curl not installed, required to download Maven, install using package manager ..."
	executeExpression "$atomicPath/automation/provisioning/base.sh curl"
	executeExpression "curl --version"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] curl : $test"
fi	

echo
executeExpression "$atomicPath/automation/provisioning/installOracleJava.sh jdk"
executeExpression "$atomicPath/automation/provisioning/installApacheMaven.sh"
executeExpression "$atomicPath/automation/remote/capabilities.sh"

echo
echo "[$scriptName] --- end ---"

