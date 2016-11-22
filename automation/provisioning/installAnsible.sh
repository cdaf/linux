#!/usr/bin/env bash

function executeExpression {
	counter=0
	max=10
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName] $1"
		eval $1
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			counter=$((portCounter + 1))
			if [ $counter -lt $max ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying ${counter} of ${max}"
			fi
		else
			success='yes'
		fi
	done
}  

scriptName='installAnsible.sh'

echo "[$scriptName] --- start ---"
systemWide=$1
if [ -z "$systemWide" ]; then
	systemWide='yes'
	echo "[$scriptName]   systemWide   : $systemWide (default)"
else
	if [ "$systemWide" == 'yes' ] || [ "$systemWide" == 'no' ]; then
		echo "[$scriptName]   systemWide   : $systemWide"
	else
		echo "[$scriptName] Expecting yes or no, exiting with error code 1"; exit 1
	fi
fi

version=$2
if [ -z "$version" ]; then
	echo "[$scriptName]   version      : Not supplied, will use default"
else
	echo "[$scriptName]   version      : $version"
	export ansibleVersion="-${version}"
fi
echo
centos=$(uname -mrs | grep .el)
if [ "$centos" ]; then
	echo "[$scriptName]   Fedora based : $(uname -mrs)"
else
	ubuntu=$(uname -a | grep buntu)
	if [ "$ubuntu" ]; then
		echo "[$scriptName]   Debian based : $(uname -mrs)"
	else
		echo "[$scriptName]   echo; echo;$(uname -a), proceeding assuming Debian based..."; echo
	fi
fi

if [ "$centos" ]; then # Fedora

	echo "[$scriptName] TODO: Fedora not implemented."
	# For non-system wide install
	# yum install gcc openssl-devel libffi-devel python-devel

else # Debian


	if [ "$systemWide" == 'yes' ]; then
		executeExpression "sudo apt-get install software-properties-common"
		executeExpression "sudo apt-add-repository ppa:ansible/ansible${ansibleVersion} -y"
		executeExpression "sudo apt-get update"
		executeExpression "sudo apt-get install -y ansible"
			
	else
		echo
		echo "[$scriptName] Install to current users ($(whoami)) home directory ($HOME)."
		echo
		executeExpression "sudo apt-get update"
		executeExpression "sudo apt-get install -y build-essential libssl-dev libffi-dev python-dev"
		executeExpression "sudo pip install virtualenv virtualenvwrapper"
		executeExpression "source `which virtualenvwrapper.sh`"
		if [ ! -d ~/ansible${ansibleVersion} ]; then
			executeExpression "mkdir ~/ansible${ansibleVersion}"
			executeExpression "cd ~/ansible${ansibleVersion}"
			executeExpression "mkvirtualenv ansible${ansibleVersion}"
		else
			executeExpression "cd ~/ansible${ansibleVersion}"
		fi
		executeExpression "workon ansible${ansibleVersion}"
		if [ -z "$version" ]; then
			executeExpression "pip install ansible"
		else
			executeExpression "pip install ansible"
			test=$(ansible-playbook --version 2>&1)
			IFS=' ' read -ra ADDR <<< $test
			if [[ ${ADDR[1]} == *"Unexpected"* ]]; then
				# Cleanup based on http://stackoverflow.com/questions/17586987/how-to-solve-pkg-resources-versionconflict-error-during-bin-python-bootstrap-py
				echo; echo "[$scriptName] Environmnet issue encountered, cleaning"; echo
				executeExpression "rm -rf ~/.virtualenvs/ansible-2.1.0.0/lib/python2.7/site-packages/setuptools*"
				executeExpression "rm -rf ~/.virtualenvs/ansible-2.1.0.0/lib/python2.7/site-packages/distribute*"
				executeExpression "rm -rf ~/.virtualenvs/ansible-2.1.0.0/lib/python2.7/site-packages/pkg_resources.py*"
			fi
		fi
	fi

fi

test=$(ansible-playbook --version 2>&1)
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] Anisble playbook not installed!"; exit 99
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] Anisble playbook version : $test"
fi	
echo 
echo "[$scriptName] --- end ---"
