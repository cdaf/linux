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

portList=$1
if [ -z "$portList" ]; then
	portList='80'
	echo "[$scriptName]   portList     : $portList (default)"
else
	echo "[$scriptName]   portList     : $portList (can be space separated list)"
fi

transport=$2
if [ -z "$transport" ]; then
	transport='tcp'
	echo "[$scriptName]   transport    : $transport (default, can be tcp or udp)"
else
	echo "[$scriptName]   transport    : $transport"
fi

echo
if [ "$ubuntu" ]; then
	executeExpression "sudo ufw allow $portList"
else
	executeExpression "ip a"
	executeExpression "sudo firewall-cmd --get-default-zone"
	for port in ${portList}; do
		executeExpression "sudo firewall-cmd --zone=public --add-port=${port}/${transport} --permanent"
	done
	executeExpression "sudo firewall-cmd --reload"
	executeExpression "sudo firewall-cmd --state"
	executeExpression "sudo firewall-cmd --get-active-zones"
	
	firewall-cmd --zone=public --list-all
	
	# View status
	systemctl status firewalld
fi

echo "[$scriptName] : --- end ---"
