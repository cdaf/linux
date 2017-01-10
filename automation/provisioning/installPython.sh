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

	if [ "$version" == "2" ]; then
		test="`pip --version 2>&1`"
		test=$(echo $test | grep 'python ')
	else
		test="`python3 --version 2>&1`"
		test=$(echo $test | grep 'python3.')
	fi
	if [ -n "$test" ]; then
		IFS=' ' read -ra ADDR <<< $test
		test=${ADDR[1]}
		echo "[$scriptName] PIP version $test already installed."
	else
		executeExpression "curl -s -O https://bootstrap.pypa.io/get-pip.py"
		executeExpression "sudo python get-pip.py"
		executeExpression "pip --version"
	fi
else	

	if [ "$centos" ]; then # Fedora
	
		executeExpression "sudo yum install -y epel-release"
		executeExpression "sudo yum install -y python${version}*"
		executeExpression "curl -s -O https://bootstrap.pypa.io/get-pip.py"
		executeExpression "sudo python${version} get-pip.py"
		executeExpression "sudo pip install virtualenv"
	
	else # Debian
	
		if [ "$version" == "2" ]; then

			# Recurring connectivity issues adding this ppa 			
			executeExpression "sudo add-apt-repository -y ppa:fkrull/deadsnakes"
			executeExpression "sudo apt-get update"
			executeExpression "sudo apt-get install -y python2.7"
			executeExpression "sudo ln -s \$(which python2.7) /usr/bin/python"
			executeExpression "curl -s -O https://bootstrap.pypa.io/get-pip.py"
			executeExpression "sudo python${version} get-pip.py"

		else # Python != v2
			executeExpression "sudo apt-get update -y"
			executeExpression "sudo apt-get install -y python${version}*"
		fi
	fi
	
	echo "[$scriptName] List version details..."

	if [ "$version" == "2" ]; then
		executeExpression "python --version"
		executeExpression "pip --version"
	else
		executeExpression "python3 --version"
		executeExpression "pip3 --version"
	fi
fi	
 
echo "[$scriptName] --- end ---"
