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

function executeAptCheck {
	if [ -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
		executeExpression "cat /etc/apt/apt.conf.d/20auto-upgrades"
		token='APT::Periodic::Update-Package-Lists \"1\";'
		value='APT::Periodic::Update-Package-Lists \"0\";'
		executeExpression "$elevate sed -i -- \"s^$token^$value^g\" /etc/apt/apt.conf.d/20auto-upgrades"
		token='APT::Periodic::Unattended-Upgrade \"1\";'
		value='APT::Periodic::Unattended-Upgrade \"0\";'
		executeExpression "$elevate sed -i -- \"s^$token^$value^g\" /etc/apt/apt.conf.d/20auto-upgrades"
		executeExpression "cat /etc/apt/apt.conf.d/20auto-upgrades"
	fi
	test="`killall --version 2>&1`"
	if [[ "$test" != *"not found"* ]]; then
		if [[ "$elevate" == 'sudo' ]]; then
			echo "[$scriptName][executeAptCheck] sudo killall apt apt-get"
			sudo killall apt apt-get
		else
			echo "[$scriptName][executeAptCheck] killall apt apt-get"
			killall apt apt-get
		fi
	fi
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		dailyUpdate=$(ps -ef | grep apt | grep -v grep | grep -v .sh)
		if [ -n "${dailyUpdate}" ]; then
			echo; echo "[$scriptName][executeAptCheck] ${dailyUpdate}"
			IFS=' ' read -ra ADDR <<< $dailyUpdate
			echo
			if [[ "$elevate" == 'sudo' ]]; then
				echo "[$scriptName][executeAptCheck] sudo kill -9 ${ADDR[1]}"
				sudo kill -9 ${ADDR[1]}
			else
				echo "[$scriptName][executeAptCheck] kill -9 ${ADDR[1]}"
				kill -9 ${ADDR[1]}
			fi
			counter=$((counter + 1))
			if [ "$counter" -gt "$max" ]; then
				echo "[$scriptName][executeAptCheck] Failed to stop automatic update! Max retries (${max}) reached."
				exit 5003
			fi
		else
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
						echo "[$scriptName] $1 Failed with exit code $exitCode stop automatic update! Max retries (${max}) reached."
						exit 5005
					fi
					while read -r line ; do
						echo "$line"
						IFS='' read -ra arr <<< $line
						if [ "${arr[1]}" != 'PID' ]; then
							executeExpression "kill -f ${arr[1]}"
						fi
					done < <(lsof /var/lib/dpkg/lock-frontend)
				else
					success='yes'
				fi
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
