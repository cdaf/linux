#!/usr/bin/env bash
scriptName='docker.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	install='apt'
	echo "[$scriptName]   install     : $install (default apt, choices apt or latest)"
else
	install=$1
	echo "[$scriptName]   install     : $install (choices apt or latest)"
fi

# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution, only Ubuntu 14.04 currently supported"
uname -a
centos=$(uname -a | grep el)

if [ -z "$centos" ]; then
	
	if [ "$install" == 'apt' ]; then

		echo "[$scriptName] Install Ubuntu Canonical docker.io ($install)"
		sudo apt-get update
		sudo apt-get install -y docker.io

	else

		echo "[$scriptName] Install latest from Docker ($install)"
		echo "[$scriptName] Add the new GPG key"
		sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	
		echo "[$scriptName] Update sources for 14.04"
		sudo sh -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" >> /etc/apt/sources.list.d/docker.list'
			
		echo "[$scriptName] Update apt repository, purge and verify repository"
		sudo apt-get update
		sudo apt-get purge lxc-docker
		apt-cache policy docker-engine
		
		echo "[$scriptName] Install the extras for this architecture linux-image-extra-$(uname -r)"
		sudo apt-get install -y linux-image-extra-$(uname -r)
	
		echo "[$scriptName] Docker document states apparmor needs to be installed"
		sudo apt-get install -y apparmor
	
		echo "[$scriptName] Docker document states apparmor needs to be installed"
		sudo apt-get install -y docker-engine
			
	fi
else
	echo "[$scriptName] CentOS/RHEL, not yet supported"
fi
 
echo "[$scriptName] --- end ---"
