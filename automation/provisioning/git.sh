#!/usr/bin/env bash
scriptName='git.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	version='latest'
	echo "[$scriptName]   version     : $version (default apt)"
else
	version=$1
	echo "[$scriptName]   version     : $version"
fi

# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution"
uname -a
centos=$(uname -a | grep el)

if [ -z "$centos" ]; then
	
	if [ "$version" == 'latest' ]; then

		sudo add-apt-repository ppa:git-core/ppa -y
		sudo apt-get update
		sudo apt-get install git
	fi
			
else # centos
	
	echo "[$scriptName] CentOS/RHEL, not yet supported"
	
fi
 
echo "[$scriptName] --- end ---"
