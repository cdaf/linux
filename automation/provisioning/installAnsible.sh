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

scriptName='installAnsible.sh'

echo "[$scriptName] --- start ---"
systemWide=$1
if [ -z "$systemWide" ]; then
	systemWide='yes'
	echo "[$scriptName]   systemWide   : $systemWide (default)"
else
	echo "[$scriptName]   systemWide   : $systemWide"
fi

version=$2
if [ -z "$version" ]; then
	echo "[$scriptName]   version      : Not supplied, will use default"
else
	echo "[$scriptName]   version      : $version"
	version="-${version}"
fi

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

else # Debian


	if [ "$systemWide" == 'yes' ]; then
		executeExpression "sudo apt-get install software-properties-common"
		executeExpression "sudo apt-add-repository ppa:ansible/ansible${version} -y"
		executeExpression "sudo apt-get update -y"
		executeExpression "sudo apt-get install -y ansible"
	else
		executeExpression "sudo pip install virtualenv virtualenvwrapper"
		executeExpression "source `which virtualenvwrapper.sh`"
		if [ ! -d ~/ansible${version} ]; then
			executeExpression "mkdir ~/ansible${version}"
			executeExpression "cd ~/ansible${version}"
			executeExpression "mkvirtualenv ansible${version}"
		else
			executeExpression "cd ~/ansible${version}"
		fi
		executeExpression "workon ansible${version}"
		executeExpression "pip install ansible"
	fi

fi

echo "[$scriptName] List version details..."
executeExpression "python${version} --version"
 
echo "[$scriptName] --- end ---"
