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

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami       : $(whoami)"
else
	echo "[$scriptName]   whoami       : $(whoami) (elevation not required)"
fi

test="`ip -V 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName]   ip           : (not installed)"
else
	executeExpression "ip a"
fi

test="`firewall-cmd 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] firewall-cmd not installed, not action attempted, exiting normally."
else
	echo
	if [ "$ubuntu" ]; then
		executeExpression "$elevate ufw allow $portList"
	else
		executeExpression "$elevate firewall-cmd --get-default-zone"
		for port in ${portList}; do
			executeExpression "$elevate firewall-cmd --zone=public --add-port=${port}/${transport} --permanent"
		done
		executeExpression "$elevate firewall-cmd --reload"
		executeExpression "$elevate firewall-cmd --state"
		executeExpression "$elevate firewall-cmd --get-active-zones"
		
		firewall-cmd --zone=public --list-all
		
		# View status
		systemctl status firewalld
	fi
fi

echo "[$scriptName] : --- end ---"
exit 0
