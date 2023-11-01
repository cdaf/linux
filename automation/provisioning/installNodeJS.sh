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
	test="`lsof -v 2>&1`"
	if [[ "$test" != *"not found"* ]]; then
		while read -r line ; do
			echo "[$scriptName][aptLockRelease] ${line}"
			read -ra arr <<< $line
			executeExpression "$elevate kill -9 ${arr[1]}"
		done < <(lsof /var/lib/dpkg/lock-frontend | grep -v COMMAND)
	fi

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
	echo "[$scriptName] Check for daily update job"
	dailyUpdate=$(ps -ef | grep  /usr/lib/apt/apt.systemd.daily | grep -v grep)
	if [ ! -z "${dailyUpdate}" ]; then
		echo
		echo "[$scriptName] ${dailyUpdate}"
		IFS=' ' read -ra ADDR <<< $dailyUpdate
		echo
		executeRetry "$elevate kill -9 ${ADDR[1]}"
		executeRetry "sleep 5"
	fi	
	echo "[$scriptName] Check for auto upgrade job"
	if [ -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
		if [ ! -z "$(cat "/etc/apt/apt.conf.d/20auto-upgrades" | grep 1)" ]; then
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
echo; echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version="21"
	echo "[$scriptName]   version    : $version (default to latest)"
else
	echo "[$scriptName]   version    : $version"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

if [ -f '/etc/centos-release' ]; then
	echo "[$scriptName]   distro     : $(cat /etc/centos-release)"
	centos='yes'
else
	if [ -f '/etc/redhat-release' ]; then
		echo "[$scriptName]   distro     : $(cat /etc/redhat-release)"
	else
		apt='yes'
		test="`lsb_release --all 2>&1`"
		if [ $? -ne 0 ]; then
			if [ -f /etc/issue ]; then
				dist=$(cat /etc/issue)
				echo "[$scriptName]   distro     : ${dist%%\\*}"
			else
				echo "[$scriptName]   distro     : $(uname -a)"
			fi
		else
			while IFS= read -r line; do
				if [[ "$line" == *"Description"* ]]; then
					IFS=' ' read -ra ADDR <<< $line
					echo "[$scriptName]   distro     : ${ADDR[1]} ${ADDR[2]}"
				fi
			done <<< "$test"
		fi	
	fi
fi

if [[ "$apt" == 'yes' ]]; then
	export DEBIAN_FRONTEND=noninteractive
	executeAptCheck "$elevate apt-get update"
	executeAptCheck "$elevate apt-get install -y --fix-missing ca-certificates curl gnupg"

	executeExpression "$elevate mkdir -p /etc/apt/keyrings"
	executeExpression "curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | $elevate gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg"

	executeExpression "echo \"deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${version}.x nodistro main\" | $elevate tee /etc/apt/sources.list.d/nodesource.list"

	executeAptCheck "$elevate apt-get update"
	executeAptCheck "$elevate apt-get -y install nodejs"
else
	executeYumCheck "$elevate yum check-update"
	executeRetry "$elevate yum install -y gcc-c++ make"
	executeExpression "$elevate yum install https://rpm.nodesource.com/pub_${version}.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y"
	executeExpression "$elevate yum install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1"
fi

echo; echo "[$scriptName] Verify Node version"
executeRetry "npm --version"
executeRetry "node --version"

echo "[$scriptName] --- end ---"
