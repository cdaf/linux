#!/usr/bin/env bash
scriptName='docker.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	install='canon'
	echo "[$scriptName]   install     : $install (default canon, choices canon or latest)"
else
	install=$1
	echo "[$scriptName]   install     : $install (choices canon or latest)"
fi

# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution, only Ubuntu 14.04 and CentOS 7 currently supported"
uname -a
centos=$(uname -a | grep el)

if [ -z "$centos" ]; then
	
	if [ "$install" == 'canon' ]; then

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
	
	if [ "$install" == 'canon' ]; then

		if [ -f /etc/os-release ]; then 
			echo "[$scriptName] Install CentOS 7 Canonical docker.io ($install)"
			sudo yum check-update
			sudo yum install -y docker
			sudo systemctl enable docker.service
			sudo systemctl start docker.service
			sudo systemctl status docker.service
		else
			echo "[$scriptName] Install CentOS 6 from Docker repository"
			sudo sh -c "echo [dockerrepo] >> /etc/yum.repos.d/docker.repo"
			sudo sh -c "name=Docker Repository >> /etc/yum.repos.d/docker.repo"
			sudo sh -c "baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/ >> /etc/yum.repos.d/docker.repo"
			sudo sh -c "enabled=1 >> /etc/yum.repos.d/docker.repo"
			sudo sh -c "gpgcheck=1 >> /etc/yum.repos.d/docker.repo"
			sudo sh -c "gpgkey=https://yum.dockerproject.org/gpg >> /etc/yum.repos.d/docker.repo"
			echo			
			sudo cat /etc/yum.repos.d/docker.repo
			echo			
			echo "[$scriptName] Install software from repo"
			sudo yum install docker-engine
			sudo service docker start
			sudo service docker status
		fi

	else
		echo "[$scriptName] Only canonical for CentOS/RHEL supported"
	fi
fi
 
echo "[$scriptName] --- end ---"
