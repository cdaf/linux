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

function executeYumCheck {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval $1
		exitCode=$?
		# Exit 0 and 100 are both success
		if [ "$exitCode" == "100" ] || [ "$exitCode" == "0" ]; then
			success='yes'
		else
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		fi
	done
}

scriptName='bootstrap-dev.sh'
echo "[$scriptName] --- start ---"

# First check for CDAF in current directory, then check for a Vagrant VM, if not Vagrant
if [ -f './automation/CDAF.linux' ]; then
	atomicPath='./automation/provisioning'
else
	echo "[$scriptName] Provisioning directory ($atomicPath) not found in workspace, looking for alternative ..."
	if [ -f '/vagrant/automation/CDAF.linux' ]; then
		atomicPath='/vagrant/automation/provisioning'
	else
		echo "[$scriptName] $atomicPath not found for Vagrant, download latest from GitHub"
		if [ -d 'linux-master' ]; then
			executeExpression "rm -rf linux-master"
		fi
		echo "[$scriptName] $atomicPath not found for Vagrant, download latest from GitHub"
		executeExpression "curl -s -O http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
		executeExpression "tar -xzf LU-CDAF.tar.gz"
		atomicPath='./automation/provisioning'
	fi
fi

executeExpression "${atomicPath}/base.sh 'virtualbox vagrant'"

echo "[$scriptName] The base command refreshes the repositories"
echo
echo "[$scriptName] From https://code.visualstudio.com/docs/setup/linux"
test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Debian/Ubuntu"
	executeExpression "curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg"
	executeExpression "sh -c 'echo \"deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main\" > /etc/apt/sources.list.d/vscode.list'"
	executeExpression "apt-get update"
	executeExpression "sudo apt-get install -y code"
fi

executeExpression "${atomicPath}/installDocker.sh" # Docker and Compose
executeExpression "${atomicPath}/installOracleJava.sh jdk" # Docker and Compose

echo "[$scriptName] --- end ---"
