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
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami  : $(whoami)"
else
	echo "[$scriptName]   whoami  : $(whoami) (elevation not required)"
fi

# First check for CDAF in current directory, then check for a Vagrant VM, if not Vagrant, default is to use the latest from GitHub (stable='no')
if [ -d './automation/provisioning' ]; then
	atomicPath='.'
else
	echo "[$scriptName] Provisioning directory ($atomicPath) not found in workspace, looking for alternative ..."
	if [ -d '/vagrant/automation' ]; then
		atomicPath='/vagrant'
	else
		if [[ $stable == 'no' ]]; then
			echo "[$scriptName] $atomicPath not found for Vagrant, download latest from GitHub"
			if [ -d 'linux-master' ]; then
				executeExpression "rm -rf linux-master"
			fi
			executeExpression "curl -s https://codeload.github.com/cdaf/linux/zip/master --output linux-master.zip"
			executeExpression "unzip linux-master.zip"
			executeExpression "cd linux-master/"
		else
			echo "[$scriptName] $atomicPath not found for Vagrant, download latest from GitHub"
			executeExpression "curl -s -O http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
			executeExpression "tar -xzf LU-CDAF.tar.gz"
		fi
		atomicPath='.'
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
executeExpression "$elevate $atomicPath/automation/provisioning/installOracleJava.sh jdk"
executeExpression "$elevate $atomicPath/automation/provisioning/installApacheMaven.sh"
executeExpression "$atomicPath/automation/remote/capabilities.sh"

echo
echo "[$scriptName] --- end ---"

