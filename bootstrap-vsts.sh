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
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		fi
	done
}

scriptName='bootstrap-vsts.sh'
echo "[$scriptName] --- start ---"
url="$1"
if [ -z "$url" ]; then
	echo "url not passed, HALT!"
	exit 101
else
	echo "[$scriptName]   url            : $url"
fi

pat="$2"
if [ -z "$pat" ]; then
	echo "pat not passed, HALT!"
	exit 102
else
	echo "[$scriptName]   pat            : \$pat"
fi

pool="$3"
if [ -z "$pool" ]; then
	echo "[$scriptName]   pool           : (not supplied)"
else
	echo "[$scriptName]   pool           : $pool"
fi

agentName="$4"
if [ -z "$agentName" ]; then
	echo "[$scriptName]   agentName      : (not supplied)"
else
	echo "[$scriptName]   agentName      : $agentName"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami         : $(whoami)"
else
	echo "[$scriptName]   whoami         : $(whoami) (elevation not required)"
fi

echo "[$scriptName] Install Zip"
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
		echo "[$scriptName] apt-get sources failed to update after ${timeout} tries, will try with existing cache ..."
	fi
	echo
	executeExpression "$elevate apt-get install -y zip"
else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	executeYumCheck "$elevate yum check-update"
	echo
	executeExpression "$elevate yum install -y zip"
fi

echo
echo "[$scriptName] Download CDAF"
if [ -d './linux-master' ]; then
	executeExpression "rm -rf './linux-master'"
fi
executeExpression "curl -s -O https://codeload.github.com/cdaf/linux/zip/master"
executeExpression "unzip master"
executeExpression "chmod -R +x ./linux-master"
executeExpression "cd ./linux-master/"

echo
echo "[$scriptName] Create agent user and register"
executeExpression "$elevate ./automation/provisioning/addUser.sh vstsagent vstsagent yes" # VSTS Agent with sudoer access
executeExpression "./automation/provisioning/installAgent.sh $url \$pat $pool $agentName"

echo "[$scriptName] --- end ---"
