#!/usr/bin/env bash

function executeExpression {
	echo "$1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

function execute100Ignore {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$counter] $1"
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

function installCURL {
	test="`curl --version 2>&1`"
	if [[ "$test" == *"not found"* ]]; then
		executeExpression "$2 $1 install -y curl"
		test="`curl --version 2>&1`"
		if [[ "$test" == *"not found"* ]]; then
			echo "[$scriptName] curl install failed, exit with code 7230"
			exit 7230
		else
			IFS=' ' read -ra ADDR <<< $test
			test=${ADDR[1]}
			echo "[$scriptName] curl version = $test"
		fi
	else
		IFS=' ' read -ra ADDR <<< $test
		test=${ADDR[1]}
		echo "[$scriptName] curl version = $test"
	fi
}

scriptName='installDotNetCore.sh'

echo "[$scriptName] --- start ---"
sdk="$1"
if [ -z "$sdk" ]; then
	sdk='yes'
	echo "[$scriptName]   sdk     : $sdk (default)"
else
	echo "[$scriptName]   sdk     : $sdk"
fi

install="$2"
if [ -z "$install" ]; then
	if [ "$sdk" == 'yes' ]; then
		default='dotnet-sdk-2.2'
	else
		default='aspnetcore-runtime-2.2'
	fi	
	install=$default
	echo "[$scriptName]   install : $install (default)"
else
	echo "[$scriptName]   install : $install"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami  : $(whoami)"
else
	echo "[$scriptName]   whoami  : $(whoami) (elevation not required)"
fi

echo
# Determine distribution, only Ubuntu/Debian and CentOS/RHEL supported
test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Yum not available, assuming Ubuntu/Debian"
else
	echo "[$scriptName] Yum available, assuming CentOS/Red Hat"
	centos='yes'
fi

echo; echo "[$scriptName] Install base software ($install)"
if [ -z "$centos" ]; then
	echo
	echo "[$scriptName] Check that APT is available"
	dailyUpdate=$(ps -ef | grep  /usr/lib/apt/apt.systemd.daily | grep -v grep)
	if [ ! -z "${dailyUpdate}" ]; then
		echo
		echo "[$scriptName] ${dailyUpdate}"
		IFS=' ' read -ra ADDR <<< $dailyUpdate
		echo
		executeExpression "$elevate kill -9 ${ADDR[1]}"
		executeExpression "sleep 5"
	fi	
	
	echo "[$scriptName] Ubuntu/Debian, update repositories using apt-get"
	execute100Ignore "$elevate apt-get update"
	installCURL 'apt-get' $elevate

	echo
	if [ "$install" == 'update' ]; then
		echo "[$scriptName] Update only, not further action required."; echo
	else
		executeExpression "$elevate apt-get install -y apt-utils apt-transport-https"

		# Source to load $VERSION_ID
        . /etc/os-release
        executeExpression "curl -O -s https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb"
        executeExpression "$elevate dpkg -i packages-microsoft-prod.deb"
		executeExpression "$elevate apt-get update"
		executeExpression "$elevate apt-get install -y $install"
	fi
else    
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	execute100Ignore "$elevate yum check-update"
	installCURL 'yum' $elevate

	echo
	if [ "$install" == 'update' ]; then
		echo "[$scriptName] Update only, not further action required."; echo
	else
		executeExpression "$elevate rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm"
		executeExpression "$elevate yum update"
		executeExpression "$elevate yum install -y $install"
	fi
fi

# dotnet core
test=$(dotnet --version 2>/dev/null)
echo "[$scriptName] dotnet core : $test"

echo; echo "[$scriptName] --- end ---"
