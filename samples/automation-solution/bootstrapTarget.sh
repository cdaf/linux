#!/usr/bin/env bash
SOLUTION="$1"
BUILDNUMBER="$2"
TARGET="$3"

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

scriptName='bootstrapTarget.sh'

echo "[$scriptName] --- start ---"
echo "[$scriptName]  SOLUTION    : $SOLUTION"
echo "[$scriptName]  BUILDNUMBER : $BUILDNUMBER"
echo "[$scriptName]  TARGET      : $TARGET"
echo "[$scriptName] Working directory is $(pwd)"
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami         : $(whoami)"
else
	echo "[$scriptName]   whoami         : $(whoami) (elevation not required)"
fi

# First check for CDAF in current directory, then check for a Vagrant VM, if not Vagrant
if [ -d './automation/provisioning' ]; then
	atomicPath='.'
else
	echo "[$scriptName] Provisioning directory (./automation/provisioning) not found in workspace, looking for alternative ..."
	if [ -d '/vagrant/automation' ]; then
		atomicPath='/vagrant'
	else
		echo "[$scriptName] /vagrant/automation not found for Vagrant, download from CDAF published site"
		executeExpression "curl -s -O $optArg http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
		executeExpression "tar -xzf LU-CDAF.tar.gz"
		atomicPath='.'
	fi
fi

if [ -f "/opt/initialised" ]; then

	echo "/opt/initialised exists, host already intialised, delete to rerun"
	echo
	cat /opt/initialised

else

	executeExpression "$elevate $atomicPath/provisioning/base.sh curl"
	executeExpression "$elevate $atomicPath/provisioning/installOracleJava.sh jre"
	executeExpression "$elevate $atomicPath/provisioning/InstallMuleESB.sh"
	executeExpression "$elevate $atomicPath/remote/capabilities.sh"

	echo "Host intialised, create /opt/initialised file"
	executeExpression "$elevate date > /opt/initialised"
	echo
	cat /opt/initialised

fi
echo
echo "[$scriptName] --- end ---"