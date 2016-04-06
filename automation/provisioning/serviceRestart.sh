#!/usr/bin/env bash
scriptName='dockerRestart.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "Service name not passed, HALT!"
	exit 1
else
	service="$1"
	echo "[$scriptName]   service : ${service}"
fi

echo "[$scriptName] Determine distribution, only Ubuntu and CentOS currently supported"
uname -a
centos=$(uname -a | grep el)

if [ -z "$centos" ]; then

	echo "[$scriptName] CentOS 6, service ${service} restart"
	sudo service ${service} restart
	sudo service ${service} status

else	
	
	echo "[$scriptName] CentOS, determine service or systemctl"
	if [ -f /etc/os-release ]; then 
		echo "[$scriptName] CentOS 7, systemctl restart"
		sudo systemctl restart ${service}.service
		sudo systemctl status ${service}.service
	else
		echo "[$scriptName] CentOS 6, service restart"
		sudo service ${service} restart
		sudo service ${service} status
	fi
fi

echo "[$scriptName] --- end ---"
