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

function executeYumCheck {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval $1
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

scriptName='base.sh'

echo "[$scriptName] --- start ---"
install=$1
echo "[$scriptName]   install : $install"

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami  : $(whoami)"
else
	echo "[$scriptName]   whoami  : $(whoami) (elevation not required)"
fi

test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
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
		if [ "$install" == 'update' ]; then
			echo "[$scriptName] apt-get sources failed to update after ${timeout} tries."
			echo "[$scriptName] Exiting with error code ${exitCode}"
			exit $exitCode
		else
			echo "[$scriptName] apt-get sources failed to update after ${timeout} tries, will try with existing cache ..."
		fi
	fi
	echo
	if [ "$install" == 'update' ]; then
		echo "[$scriptName] Update only, not further action required."; echo
	else
		executeExpression "$elevate apt-get install -y $install"
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
