#!/usr/bin/env bash
scriptName='base.sh'

echo "[$scriptName] --- start ---"
install=$1

echo "[$scriptName]   install     : $install"

# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution, only Ubuntu/Debian and CentOS/RHEL supported"
uname -a
centos=$(uname -a | grep el)

echo "[$scriptName] Install base software ($install)"
if [ -z "$centos" ]; then
	echo "[$scriptName] Ubuntu/Debian, update repositories using apt-get"
	sudo apt-get update
	sudo apt-get install -y $install
else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	sudo yum check-update
	sudo yum install -y $install
fi
 
echo "[$scriptName] --- end ---"
