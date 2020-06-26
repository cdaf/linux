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

scriptName='installNodeJS.sh'
echo
echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	echo "[$scriptName]   version    : (not supplied, will install canonical)"
else
	echo "[$scriptName]   version    : $version"
	systemWide=$2
	if [ -z "$systemWide" ]; then
		systemWide='yes'
		echo "[$scriptName]   systemWide : $systemWide (default)"
	else
		if [ "$systemWide" == 'yes' ] || [ "$systemWide" == 'no' ]; then
			echo "[$scriptName]   systemWide : $systemWide"
		else
			echo "[$scriptName] Expecting yes or no, exiting with error code 1"; exit 1
		fi
	fi

	mediaCache="$3"
	if [ -z "$mediaCache" ]; then
		mediaCache='/.provision'
		echo "[$scriptName]   mediaCache : $mediaCache (default)"
	else
		echo "[$scriptName]   mediaCache : $mediaCache"
	fi
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
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
		echo "[$scriptName] apt-get sources failed to update after ${timeout} tries, will try with existing cache ..."
	fi
	echo
	if [ -z "$version" ]; then
		executeRetry "$elevate apt-get install -y nodejs npm curl"
		
		test="`node -v 2>&1`"
		if [[ "$test" == *"not found"* ]]; then
			echo "[$scriptName] Node not found, create symlink to NodeJS."
			executeRetry "ln -s /usr/bin/nodejs /usr/bin/node"
			test="`node -v 2>&1`"
			if [[ "$test" == *"not found"* ]]; then
				echo "[$scriptName] Install Error! Node verification failed."
				exit 939
			fi
		fi
	else
		executeRetry "$elevate apt-get install -y curl"
	fi

else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	executeYumCheck "$elevate yum check-update"

	if [ "$systemWide" == 'yes' ]; then
		
		if [ -z "$centos" ]; then # Red Hat Enterprise Linux (RHEL)
			echo "[$scriptName] Red Hat Enterprise Linux"
		    executeIgnore "$elevate yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
		else
			executeRetry "$elevate yum install -y epel-release"
		fi
	fi

	echo
	if [ -z "$version" ]; then
		executeRetry "$elevate yum install -y curl sudo gcc-c++ make"
		echo;echo "[$scriptName] Aligning to Ubuntu 16.04 canonical version, i.e. v4"
		executeRetry "curl --silent --location https://rpm.nodesource.com/setup_4.x | $elevate bash -"
		executeRetry "$elevate yum install -y nodejs"
	else
		executeRetry "$elevate yum install -y curl"
	fi

fi

if [ ! -z "$version" ]; then

	test="`curl --version 2>&1`"
	if [[ "$test" == *"not found"* ]]; then
		echo; echo "[$scriptName] Install Error! curl verification failed."
		exit 934
	fi	
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] curl : $test"
	
	if [ -z "$fedora" ]; then # Debian
		echo
		if [ -z $elevate ]; then
			executeRetry "curl -sL https://deb.nodesource.com/setup_${version}.x | bash -"
		else
			executeRetry "curl -sL https://deb.nodesource.com/setup_${version}.x | $elevate -E bash -"
		fi
		executeRetry "$elevate apt-get install -y nodejs"
	else # Red Hat
		executeRetry "$elevate yum install -y gcc-c++ make"
		if [ -z $elevate ]; then
			executeRetry "curl -sL https://rpm.nodesource.com/setup_${version}.x | bash -"
		else
			executeRetry "curl -sL https://rpm.nodesource.com/setup_${version}.x | $elevate -E bash -"
		fi
		executeRetry "$elevate yum install -y nodejs"
		
	fi
		
	# NodeJS components
	test=$(node --version 2>/dev/null)
	if [ -z "$test" ]; then
		echo "[$scriptName] NodeJS           : (not installed)"
	else
		echo "[$scriptName] NodeJS           : $test"
	fi	
	
	# Node Package Manager
	test=$(npm -version 2>/dev/null)
	if [ -z "$test" ]; then
		echo "[$scriptName] NPM              : (not installed)"
	else
		echo "[$scriptName] NPM              : $test"
	fi	

fi

echo; echo "[$scriptName] Verify Node version"
executeRetry "npm --version"
executeRetry "node --version"

echo "[$scriptName] --- end ---"
