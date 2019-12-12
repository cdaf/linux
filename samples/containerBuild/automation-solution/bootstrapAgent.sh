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

# First check for CDAF in current directory, then check for a Vagrant VM, if not Vagrant, default is to use the latest from GitHub (stable='no')
defaultPath='./automation'
if [ -d "${defaultPath}/provisioning" ]; then
	atomicPath="$defaultPath"
else
	echo "[$scriptName] Provisioning directory ($defaultPath) not found in workspace, looking for alternative ..."
	if [ -d '/vagrant/automation/provisioning' ]; then
		atomicPath='/vagrant/automation'
		echo "[$scriptName] Vagrant synchronised directory ($atomicPath) found"
	else
		if [[ $stable == 'no' ]]; then
			echo "[$scriptName] $atomicPath not found for Vagrant, download latest from GitHub"
			if [ -d 'linux-master' ]; then
				executeExpression "rm -rf linux-master"
			fi
			executeExpression "curl -s https://codeload.github.com/cdaf/linux/zip/master --output linux-master.zip"
			executeExpression "unzip linux-master.zip"
			atomicPath='./linux-master/automation'
		else
			echo "[$scriptName] $atomicPath not found for Vagrant, download latest from GitHub"
			executeExpression "curl -s -O http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
			executeExpression "tar -xzf LU-CDAF.tar.gz"
			atomicPath="$defaultPath"
		fi
	fi
fi

echo
test="`curl --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] curl not installed, required to download Maven, install using package manager ..."
	executeExpression "$atomicPath/provisioning/base.sh curl"
	executeExpression "curl --version"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] curl : $test"
fi	

echo
executeExpression "$elevate $atomicPath/provisioning/base.sh openjdk-11-jdk"
executeExpression "$elevate $atomicPath/provisioning/installApacheMaven.sh"
executeExpression "$atomicPath/remote/capabilities.sh"

echo
echo "[$scriptName] --- end ---"

