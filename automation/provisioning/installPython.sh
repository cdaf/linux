#!/usr/bin/env bash

function executeExpression {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval "$1"
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

function executeYumCheck {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval "$1"
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

function executeIgnore {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		if [ "$exitCode" == "1" ]; then
			echo "$0 : Warning: Returned $exitCode assuming already installed and continuing ..."
		else
			echo "$0 : Error! Returned $exitCode, exiting!"; exit $exitCode 
		fi
	fi
	return $exitCode
}

scriptName='installPython.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	version='3'
	echo "[$scriptName]   version : $version (default)"
else
	version=$1
	echo "[$scriptName]   version : $version (choices 2 or 3)"
fi

install=$2
if [ -z "$install" ]; then
	echo "[$scriptName]   install : (PiP install list not supplied, no additional action will be attempted)"
else
	echo "[$scriptName]   install : $install"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami  : $(whoami)"
else
	echo "[$scriptName]   whoami  : $(whoami) (elevation not required)"
fi

test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] yum not found, assuming Debian/Ubuntu, using apt-get"
else
	fedora='yes'
	centos=$(cat /etc/redhat-release | grep CentOS)
	if [ -z "$centos" ]; then
		echo "[$scriptName] Red Hat Enterprise Linux"
	else
		echo "[$scriptName] CentOS Linux"
	fi
fi
echo

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
		if [ "$version" == "2" ]; then
			executeExpression "$elevate python get-pip.py"
		else
			executeExpression "$elevate python${version} get-pip.py"
		fi
		executeExpression "pip --version"
	fi
else	

	if [ -z "$fedora" ]; then
		echo "[$scriptName] Debian/Ubuntu, update repositories using apt-get"
		echo
		echo "[$scriptName] Check that APT is available"
		dailyUpdate=$(ps -ef | grep  /usr/lib/apt/apt.systemd.daily | grep -v grep)
		if [ -n "${dailyUpdate}" ]; then
			echo
			echo "[$scriptName] ${dailyUpdate}"
			IFS=' ' read -ra ADDR <<< $dailyUpdate
			echo
			executeExpression "$elevate kill -9 ${ADDR[1]}"
			executeExpression "sleep 5"
		fi	
		
		echo "[$scriptName] $elevate apt-get update"
		echo
		timeout=3
		count=0
		while [ ${count} -lt ${timeout} ]; do
			$elevate apt-get update
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

		if [ "$version" == "2" ]; then

			release=$(lsb_release -r | grep 14.04)
			if [[ "$release" == *"14.04"* ]]; then
			
				# 14.04
				executeExpression "$elevate add-apt-repository -y ppa:fkrull/deadsnakes"
				executeExpression "$elevate apt-get update"
				executeExpression "$elevate apt-get install -y python2.7"
				executeExpression "$elevate ln -s \$(which python2.7) /usr/bin/python"
				executeExpression "curl -s -O https://bootstrap.pypa.io/get-pip.py"
				executeExpression "$elevate python${version} get-pip.py"
			else
				# 16.04 and above
				executeExpression "$elevate -y python-software-properties"
			fi

		else # Python != v2
			executeExpression "$elevate apt-get update -y"
			executeExpression "$elevate apt-get install -y python${version}*"
		fi

	else
		echo "[$scriptName] CentOS/RHEL, update repositories using yum"
		centos='yes'
		executeYumCheck "$elevate yum check-update"
	
		echo

		if [ "$systemWide" == 'yes' ]; then
			if [ -z "$centos" ]; then # Red Hat Enterprise Linux (RHEL)
				echo "[$scriptName] Red Hat Enterprise Linux"
			    executeIgnore "$elevate yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
			else
				executeExpression "$elevate yum install -y epel-release"
			fi
			executeExpression "$elevate yum install -y ansible"
		fi

		executeExpression "$elevate yum install -y python${version}*"
		executeExpression "curl -s -O https://bootstrap.pypa.io/get-pip.py"
		executeExpression "$elevate python${version} get-pip.py"
		executeExpression "$elevate pip install virtualenv"
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

if [ ! -z "$install" ]; then
	if [ "$version" == "2" ]; then
		executeExpression "pip install $install"
	else
		executeExpression "pip${$version} install $install"
	fi
fi
 
echo "[$scriptName] --- end ---"
