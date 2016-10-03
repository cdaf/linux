#!/usr/bin/env bash
scriptName='addDockerOpts.sh'

echo "[$scriptName] --- start ---"
option=$1
if [ -z "$option" ]; then
	option='--insecure-registry'
	echo "[$scriptName]   option : $option (default)"
else
	echo "[$scriptName]   option : $option"
fi

value=$2
if [ -z "$value" ]; then
	value='172.16.17.103:5000'
	echo "[$scriptName]   value  : $value (default)"
else
	echo "[$scriptName]   value  : $value"
fi
echo "[$scriptName] Determine distribution, only Ubuntu/Debian and CentOS/RHEL supported"
uname -a
centos=$(uname -a | grep el)

if [ -z "$centos" ]; then
	defaultConfig='/etc/default/docker'
	echo "[$scriptName] Ubuntu/Debian, default config is $defaultConfig"
	line="DOCKER_OPTS=\\\"\\\$DOCKER_OPTS $option=$value\\\""
else
	defaultConfig='/etc/sysconfig/docker'
	echo "[$scriptName] CentOS/RHEL, default config is $defaultConfig"
	line="OPTIONS=\\\"--selinux-enabled --log-driver=journald $option=$value\\\""
	sudo sh -c "echo \"DOCKER_CERT_PATH=/etc/docker \" > $defaultConfig"
	
fi
echo		
echo "Requires elevated session to write to config file"
echo
echo "sudo sh -c \"echo \"$line \" >> $defaultConfig\""
sudo sh -c "echo \"$line \" >> $defaultConfig"
echo 
echo "[$scriptName] --- end ---"
