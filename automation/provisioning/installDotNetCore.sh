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

scriptName='installDotNetCore.sh'

echo "[$scriptName] --- start ---"
install=dotnet-dev-1.0.4
echo "[$scriptName]   install : $install"
echo
# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution, only Ubuntu/Debian and CentOS/RHEL supported"
uname -a
centos=$(uname -a | grep el)

echo
echo "[$scriptName] Install base software ($install)"
if [ -z "$centos" ]; then
	echo
	echo "[$scriptName] Check that APT is available"
	dailyUpdate=$(ps -ef | grep  /usr/lib/apt/apt.systemd.daily | grep -v grep)
	if [ -n "${dailyUpdate}" ]; then
		echo
		echo "[$scriptName] ${dailyUpdate}"
		IFS=' ' read -ra ADDR <<< $dailyUpdate
		echo
		executeExpression "sudo kill -9 ${ADDR[1]}"
		executeExpression "sleep 5"
	fi	
	
	echo "[$scriptName] Ubuntu/Debian, update repositories using apt-get"
	echo "[$scriptName] sudo apt-get update"
	echo
	timeout=3
	count=0
	while [ ${count} -lt ${timeout} ]; do
		sudo apt-get update
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
	if [ "$install" == 'update' ]; then
		echo "[$scriptName] Update only, not further action required."; echo
	else
        . /etc/os-release
        echo "[$scriptName] Detected Ubuntu Version: $VERSION_ID"
        
        if [ "$VERSION_ID" == "14.04" ]; then
            executeExpression "sudo sh -c 'echo \"deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet-release/ trusty main\" > /etc/apt/sources.list.d/dotnetdev.list'"
            executeExpression "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 417A0893"
            executeExpression "sudo apt-get update"            
        elif [ "$VERSION_ID" == "16.04" ]; then
            executeExpression "sudo sh -c 'echo \"deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet-release/ xenial main\" > /etc/apt/sources.list.d/dotnetdev.list'"
            executeExpression "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 417A0893"
            executeExpression "sudo apt-get update"
        elif [ "$VERSION_ID" == "16.10" ]; then
            executeExpression "sudo sh -c 'echo \"deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet-release/ yakkety main\" > /etc/apt/sources.list.d/dotnetdev.list'"
            executeExpression "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 417A0893"
            executeExpression "sudo apt-get update"
        else
            echo "[$scriptName] Ubuntu Version $VERSION_ID not supported by #scriptName"
            exit 1
        fi
        
		executeExpression "sudo apt-get install -y $install"
	fi
else    
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	echo "[$scriptName] sudo yum check-update"
	echo
	timeout=3
	count=0
	while [ ${count} -lt ${timeout} ]; do
		sudo yum check-update
		exitCode=$?
		if [ "$exitCode" != "100" ]; then
	   	    ((count++))
			echo "[$scriptName] yum sources update failed with exit code $exitCode, retry ${count}/${timeout} "
		else
			count=${timeout}
		fi
	done
	if [ "$exitCode" != "100" ]; then
		echo "[$scriptName] yum sources failed to update after ${timeout} tries."
		echo "[$scriptName] Exiting with error code ${exitCode}"
		exit $exitCode
	fi
	echo
	if [ "$install" == 'update' ]; then
		echo "[$scriptName] Update only, not further action required."; echo
	else
		executeExpression "sudo yum install -y libunwind libicu"
		executeExpression "curl -sSL -o dotnet.tar.gz https://go.microsoft.com/fwlink/?linkid=848821"
		executeExpression "sudo mkdir -p /opt/dotnet && sudo tar zxf dotnet.tar.gz -C /opt/dotnet"
		executeExpression "sudo ln -s /opt/dotnet/dotnet /usr/local/bin"
	fi
fi
 
echo "[$scriptName] --- end ---"
