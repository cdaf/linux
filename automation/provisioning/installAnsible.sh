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

scriptName='installAnsible.sh'

echo "[$scriptName] --- start ---"
systemWide=$1
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

version=$2
if [ -z "$version" ]; then
	echo "[$scriptName]   version    : Not supplied, will use default"
else
	echo "[$scriptName]   version    : $version"
	export ansibleVersion="-${version}"
fi
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

if [ -f '/etc/centos-release' ]; then
	distro=$(cat "/etc/centos-release")
	echo "[$scriptName]   distro     : $distro"
	fedora='yes'
else
	if [ -f '/etc/redhat-release' ]; then
		distro=$(cat "/etc/redhat-release")
		echo "[$scriptName]   distro     : $distro"
		fedora='yes'
	else
		debian='yes'
		test=$(lsb_release --all 2>&1)
		if [[ "$test" == *"not found"* ]]; then
			if [ -f "/etc/issue" ]; then
				distro=$(cat "/etc/issue")
				echo "[$scriptName]   distro     : $distro"
			else
				distro=$(uname -a)
				echo "[$scriptName]   distro     : $distro"
			fi
		else
			while IFS= read -r line; do
				if [[ "$line" == *"Description"* ]]; then
					IFS=' ' read -ra ADDR <<< $line
					distro=$(echo "${ADDR[1]} ${ADDR[2]}")
					echo "[$scriptName]   distro     : $distro"
				fi
			done <<< "$test"
			if [ -z "$distro" ]; then
				echo "[$scriptName] HALT! Unable to determine distribution!"; exit 774
			fi
		fi	
	fi
fi
echo

if [ "$fedora" == 'yes' ]; then
	IFS='.' read -ra ADDR <<< $distro
	distro=$(echo "${ADDR[0]##* }")
fi

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

	echo
	if [ "$systemWide" == 'yes' ]; then

		executeRetry "$elevate apt-get install -y software-properties-common"
		executeRetry "$elevate apt-add-repository ppa:ansible/ansible${ansibleVersion} -y"
		executeRetry "$elevate apt-get update"
		executeRetry "$elevate apt-get install -y ansible"
			
	else
		executeRetry "$elevate apt-get update"
		executeRetry "$elevate apt-get install -y build-essential libssl-dev libffi-dev python-dev"
	fi
	
else
	if [ $distro -gt 7 ]; then
		echo "[$scriptName] CentOS/RHEL, update repositories using DNF"
		executeRetry "$elevate dnf update -y"
		executeRetry "$elevate dnf install -y epel-release"
		executeRetry "$elevate dnf install -y ansible"
	else
		echo "[$scriptName] CentOS/RHEL, update repositories using yum"
		executeYumCheck "$elevate yum check-update"
		executeRetry "$elevate yum install -y gcc openssl-devel libffi-devel python-devel"
		if [ "$systemWide" == 'yes' ]; then
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
			executeRetry "$elevate yum install -y ansible"
		fi
	fi
fi

if [ "$systemWide" == 'no' ]; then
	echo
	echo "[$scriptName] Install to current users ($(whoami)) home directory ($HOME)."
	echo
	# Distribution specific dependencies installed above, this process is generic for all distributions 
	executeRetry "$elevate pip install virtualenv virtualenvwrapper"
	executeRetry "source `which virtualenvwrapper.sh`"
	if [ ! -d ~/ansible${ansibleVersion} ]; then
		executeRetry "mkdir ~/ansible${ansibleVersion}"
		executeRetry "cd ~/ansible${ansibleVersion}"
		executeRetry "mkvirtualenv ansible${ansibleVersion}"
	else
		executeRetry "cd ~/ansible${ansibleVersion}"
	fi
	executeRetry "workon ansible${ansibleVersion}"
	if [ -z "$version" ]; then
		executeRetry "pip install ansible"
	else
		executeRetry "pip install ansible==${version}"
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
