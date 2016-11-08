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

scriptName='installPython.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	version='3'
	echo "[$scriptName]   version      : $version (default)"
else
	version=$1
	echo "[$scriptName]   version      : $version (choices 2 or 3)"
fi

centos=$(uname -mrs | grep .el)
if [ "$centos" ]; then
	echo "[$scriptName]   Fedora based : $(uname -mrs)"
else
	ubuntu=$(uname -a | grep buntu)
	if [ "$ubuntu" ]; then
		echo "[$scriptName]   Debian based : $(uname -mrs)"
	else
		echo "[$scriptName]   $(uname -a), proceeding assuming Debian based..."; echo
	fi
fi

if [ "$version" == "2" ]; then
	test="`python --version 2>&1`"
	test=$(echo $test | grep 'Python 2.')
else
	test="`python3 --version 2>&1`"
	test=$(echo $test | grep 'Python 3.')
fi

if [ -n "$test" ]; then
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] Python version $test already installed, install PIP only."
	executeExpression "curl https://bootstrap.pypa.io/get-pip.py | sudo python"
else	

	if [ "$centos" ]; then # Fedora
	
		executeExpression "sudo yum install -y epel-release"
		executeExpression "sudo yum install -y python${version}*"
		executeExpression "curl https://bootstrap.pypa.io/get-pip.py | sudo python${version}"
		executeExpression "sudo pip install virtualenv"
	
	else # Debian
	
		if [ "$version" == "3" ]; then
			executeExpression "sudo apt-get update -y"
			executeExpression "sudo apt-get install -y python${version}*"
		else
			executeExpression "sudo add-apt-repository -y ppa:fkrull/deadsnakes"
			executeExpression "sudo apt-get update"
			executeExpression "sudo apt-get install -y python2.7"
			executeExpression "sudo ln -s \$(which python2.7) /usr/bin/python"
			executeExpression "curl https://bootstrap.pypa.io/get-pip.py | sudo python"
		fi
	
	fi
	
	echo "[$scriptName] List version details..."

	if [ "$version" == "2" ]; then
		executeExpression "python --version"
	else
		executeExpression "python3 --version"
	fi
fi	
 
echo "[$scriptName] --- end ---"
