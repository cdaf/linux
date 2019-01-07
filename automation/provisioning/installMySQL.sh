#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='installMySQL.sh'

echo "[$scriptName] --- start ---"
prefix="$1"
if [ -z "$prefix" ]; then
	echo "[$scriptName]   password : (none)"
else
	echo "[$scriptName]   password : ****************"
fi

version="$2"
if [ -z "$version" ]; then
	version='5.7'
	install='mysql-server'
	echo "[$scriptName]   version  : $version (default, $install)"
else
	install="mysql-server-$version"
	echo "[$scriptName]   version  : $version ($install)"
fi

# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution"
uname -a
centos=$(uname -a | grep el)
if [ -z "$centos" ]; then
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
	# debconf-utils allows the passing of answer values
	executeExpression 'sudo apt-get install -y debconf-utils'
	echo "[$scriptName] Load installer responses"
	echo "[$scriptName]   sudo debconf-set-selections <<< \"$install mysql-server/root_password password \$password\""
	sudo debconf-set-selections <<< "$install mysql-server/root_password password $password"
	echo "[$scriptName]   sudo debconf-set-selections <<< \"$install  mysql-server/root_password_again password \$password\""
	sudo debconf-set-selections <<< "$install mysql-server/root_password_again password $password"
	sudo apt-get install -y $install
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
	
else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	echo "[$scriptName] sudo yum check-update"
	echo
	timeout=3
	count=0
	while [ $count -lt $timeout ]; do
		# A "normal" exit code is 100, so cannot use executeExpression
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
	
	executeExpression "sudo yum install -y mariadb-server mariadb"
	executeExpression "sudo iptables -I INPUT -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT"
	executeExpression "sudo iptables -I OUTPUT -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT"
	executeExpression "sudo systemctl enable mariadb.service"
	executeExpression "sudo systemctl start mariadb.service"

fi

echo "[$scriptName] --- end ---"

