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

scriptName='base.sh'

echo "[$scriptName] --- start ---"
install=$1
echo "[$scriptName]   install     : $install"

# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution, only Ubuntu/Debian and CentOS/RHEL supported"
uname -a
centos=$(uname -a | grep el)

echo

echo "[$scriptName] Install base software ($install)"
if [ -z "$centos" ]; then
	echo "[$scriptName] Ubuntu/Debian, update repositories using apt-get"
	echo "[$scriptName] sudo apt-get update"
	echo
	timeout=3
	count=0
	while [ ${count} -lt ${timeout} ]; do
		sudo apt-get update
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
	   	    ((count++))
			echo "[$scriptName] apt-get sources update failed with exit code $exitCode, retry ${count}/${timeout} "
		else
			count=${timeout}
		fi
	done
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] apt-get sources failed to update after ${timeout} tries."
		echo "[$scriptName] Exiting with error code ${exitCode}"
		exit $exitCode
	fi
	echo
	executeExpression "sudo apt-get install -y $install"
else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	echo "[$scriptName] sudo yum check-update"
	echo
	timeout=3
	count=0
	while [ ${count} -lt ${timeout} ]; do
		sudo yum check-update
		exitCode=$?
		if [ "$exitCode" != "100" ]; then
	   	    ((count++))
			echo "[$scriptName] yum sources update failed with exit code $exitCode, retry ${count}/${timeout} "
		else
			count=${timeout}
		fi
	done
	if [ "$exitCode" != "100" ]; then
		echo "[$scriptName] yum sources failed to update after ${timeout} tries."
		echo "[$scriptName] Exiting with error code ${exitCode}"
		exit $exitCode
	fi
	echo
	executeExpression "sudo yum install -y $install"
fi
 
echo "[$scriptName] --- end ---"
