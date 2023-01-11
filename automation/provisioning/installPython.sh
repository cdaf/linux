#!/usr/bin/env bash

function executeRetry {
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
	echo "[$scriptName]   version : $version (default, choices 2 or 3)"
else
	version=$1
	echo "[$scriptName]   version : $version (choices 2 or 3)"
fi

if [ "$version" != "2" ]; then
	pyVer=$version
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
	test=$(rpm --query redhat-release 2>&1)
	if [ $? -eq 0 ]; then
		echo "[$scriptName] Red Hat Enterprise Linux $test"
	else
		centos=$(rpm --query centos-release)
		echo "[$scriptName] CentOS Linux $centos"
		
	fi
fi
echo

if [ -z "$fedora" ]; then
	echo "[$scriptName] Debian/Ubuntu, update repositories using apt-get"
	echo
	echo "[$scriptName] Check that APT is available"
	dailyUpdate=$(ps -ef | grep  /usr/lib/apt/apt.systemd.daily | grep -v grep)
	if [ ! -z "${dailyUpdate}" ]; then
		echo
		echo "[$scriptName] ${dailyUpdate}"
		IFS=' ' read -ra ADDR <<< $dailyUpdate
		echo
		executeRetry "$elevate kill -9 ${ADDR[1]}"
		executeRetry "sleep 5"
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

	executeRetry "$elevate apt-get update -y"
	executeRetry "$elevate apt-get install -y python${pyVer}-pip"

else

	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	centos='yes'
	executeYumCheck "$elevate yum check-update"

	echo
	if [ -z "$centos" ]; then # Red Hat Enterprise Linux (RHEL)
		echo "[$scriptName] Red Hat Enterprise Linux"
		version=$(cat /etc/redhat-release)
		IFS='.' read -ra arr <<< $version
		IFS=' ' read -ra arr <<< ${arr[0]}
		epelversion=$(echo ${arr[${#arr[@]} - 1]})
	    executeIgnore "$elevate yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${epelversion}.noarch.rpm" # Ignore if already installed
	else
		executeRetry "$elevate yum install -y epel-release"
	fi
	executeYumCheck "$elevate yum check-update"
	executeRetry "$elevate yum install -y python${pyVer}-pip"
fi

echo "[$scriptName] List version details..."

executeRetry "python${pyVer} --version"
executeRetry "pip${pyVer} --version"

if [ ! -z "$install" ]; then
	executeRetry "$elevate pip${pyVer} install $install"
fi

echo "[$scriptName] --- end ---"
