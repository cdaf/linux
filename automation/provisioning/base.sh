#!/usr/bin/env bash

function executeExpression {
	echo "[executeExpression] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

function executeYumCheck {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][executeYumCheck][$counter] $1"
		eval "$1"
		exitCode=$?
		# Exit 0 and 100 are both success
		if [ "$exitCode" == "100" ] || [ "$exitCode" == "0" ]; then
			success='yes'
		else
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max} after 20 second pause ..."
				sleep 20
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi
		fi
	done
}

function aptLockRelease {
	test="`killall --version 2>&1`"
	if [[ "$test" != *"not found"* ]]; then
		if [[ "$elevate" == 'sudo' ]]; then
			echo "[$scriptName][aptLockRelease] sudo killall apt apt-get"
			sudo killall apt apt-get
		else
			echo "[$scriptName][aptLockRelease] killall apt apt-get"
			killall apt apt-get
		fi
	fi

	unset IFS
	while read -r line ; do
		echo "[$scriptName][aptLockRelease] ${line}"
		read -ra arr <<< $line
		executeExpression "$elevate kill -9 ${arr[1]}"
	done < <(lsof /var/lib/dpkg/lock-frontend | grep -v COMMAND)

	while read -r line ; do
		echo "[$scriptName][aptLockRelease] ${line}"
		read -ra arr <<< $line
		if [[ "$elevate" == 'sudo' ]]; then
			echo "[$scriptName][aptLockRelease] sudo kill -9 ${arr[1]}"
			sudo kill -9 ${arr[1]}
		else
			echo "[$scriptName][aptLockRelease] kill -9 ${arr[1]}"
			kill -9 ${arr[1]}
		fi
	done < <(ps -ef | grep apt | grep -v grep | grep -v .sh)
}

function executeAptCheck {
	if [ -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
		if [ -n "$(cat "/etc/apt/apt.conf.d/20auto-upgrades" | grep 1)" ]; then
			executeExpression "cat /etc/apt/apt.conf.d/20auto-upgrades"
			token='APT::Periodic::Update-Package-Lists \"1\";'
			value='APT::Periodic::Update-Package-Lists \"0\";'
			executeExpression "$elevate sed -i -- \"s^$token^$value^g\" /etc/apt/apt.conf.d/20auto-upgrades"
			token='APT::Periodic::Unattended-Upgrade \"1\";'
			value='APT::Periodic::Unattended-Upgrade \"0\";'
			executeExpression "$elevate sed -i -- \"s^$token^$value^g\" /etc/apt/apt.conf.d/20auto-upgrades"
			executeExpression "cat /etc/apt/apt.conf.d/20auto-upgrades"
			aptLockRelease
		fi
	fi
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		if [ -z "$1" ]; then
			success='yes'
		else
			echo "[$(date)] $1"
			eval "$1"
			exitCode=$?
			# Check execution normal, anything other than 0 is an exception
			if [ "$exitCode" != "0" ]; then
				counter=$((counter + 1))
				if [ "$counter" -gt "$max" ]; then
					echo "[$scriptName] $1 Failed with exit code ${exitCode}! Max retries (${max}) reached."
					exit 5005
				fi
				aptLockRelease
			else
				success='yes'
			fi
		fi
	done
}

scriptName='base.sh'

echo "[$scriptName] --- start ---"
install=$1
echo "[$scriptName]   install    : $install"

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

if [ -n "$http_proxy" ]; then
	echo "[$scriptName]   http_proxy : $http_proxy"
else
	echo "[$scriptName]   http_proxy : (not set)"
fi

test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	apt='yes'
	echo "[$scriptName] Debian/Ubuntu, update repositories using apt-get"; echo
	echo "[$scriptName] Check that APT is available"
	executeAptCheck

	echo "[$scriptName] $elevate apt-get update"; echo
		executeAptCheck "$elevate apt-get update"
	echo
	if [ "$install" == 'update' ]; then
		echo "[$scriptName] Update only, not further action required."; echo
	else
		executeAptCheck "$elevate apt-get install -y --fix-missing $install"
	fi
else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	executeYumCheck "$elevate yum check-update"

	echo
	if [ "$install" == 'update' ]; then
		echo "[$scriptName] Update only, not further action required."; echo
	else
		executeExpression "$elevate yum install -y $install"
	fi
fi
 
echo "[$scriptName] --- end ---"
