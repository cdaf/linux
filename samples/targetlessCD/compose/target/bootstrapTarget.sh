#!/usr/bin/env bash
function executeExpression {
	counter=1
	max=2
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
				echo "[$scriptName][CDAF_DELIVERY_FAILURE] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		else
			success='yes'
		fi
	done
}  

scriptName='bootstrapTarget.sh'

echo "[$scriptName] --- start ---"

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

if [ ! -z "$http_proxy" ]; then
	echo "[$scriptName]   http_proxy : $http_proxy"
	optArg="--proxy $http_proxy"
else
	echo "[$scriptName]   http_proxy : (not set)"
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

executeExpression "$atomicPath/automation/provisioning/base.sh 'curl'"
executeExpression "$atomicPath/automation/remote/capabilities.sh"

echo; echo "[$scriptName] --- end ---"

