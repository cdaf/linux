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

scriptName='openFirewallPort.sh'
echo
echo "[$scriptName] : --- start ---"
centos=$(uname -mrs | grep .el)
if [ "$centos" ]; then
	echo "[$scriptName]   Fedora based : $(uname -mrs)"
else
	ubuntu=$(uname -a | grep ubuntu)
	if [ "$ubuntu" ]; then
		echo "[$scriptName]   Debian based : $(uname -mrs)"
	else
		echo "[$scriptName]   $(uname -a), proceeding assuming Debian based..."; echo
	fi
fi

if [ -z "$1" ]; then
	port='80'
	echo "[$scriptName]   port         : $port (default)"
else
	port=$1
	echo "[$scriptName]   port         : $port"
fi
echo
if [ "$ubuntu" ]; then
	executeExpression "sudo ufw allow $port"
else
	executeExpression "ip a"
	executeExpression "sudo firewall-cmd --get-default-zone"
	executeExpression "sudo firewall-cmd --zone=public --add-port=$port/tcp --permanent"
	executeExpression "sudo firewall-cmd --reload"
	executeExpression "sudo firewall-cmd --state"
	executeExpression "sudo firewall-cmd --get-active-zones"
	
	firewall-cmd --zone=public --list-all
	
	# View status
	systemctl status firewalld
fi

echo "[$scriptName] : --- end ---"
