#!/usr/bin/env bash
scriptName='curl.sh'

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

	echo "[$scriptName] Install $version on Ubuntu"
	if [ "$version" == 'latest' ]; then
		
		sudo add-apt-repository ppa:costamagnagianfranco/ettercap-stable-backports -y
		sudo apt-get update
		sudo apt-get install -y curl
			
	else
	
		echo "[$scriptName] Install compiler tools"
		sudo apt-get install -y libtool make
	
		echo "[$scriptName] Compile for Ubuntu"
		echo "[$scriptName] Download and extract source"
	
		# Don't use curl as it cannot navigate the redirection
		currentDir=$(pwd)
		cd ~
		wget http://curl.haxx.se/download/curl-${version}.tar.gz
		tar -xvf curl-${version}.tar.gz
	
		echo "[$scriptName] Compile the software"
		cd curl-${version}
		./buildconf
		./configure
		make
		sudo make install
		
		echo "[$scriptName] Replace the existing version"
		sudo mv /usr/bin/curl /usr/bin/curl.bak
		# cp /usr/local/bin/curl /usr/bin/curl
		sudo ln -s /usr/local/bin/curl /usr/bin/curl
		
		cd $currentDir
	fi
	echo "[$scriptName] Verify version"
	curl -V

else # centos

	echo "[$scriptName] Install $version on CentOS"
	if [ "$version" == 'latest' ]; then
		
		if [ -f /etc/os-release ]; then 
			versionID='rhel7'
		else
			versionID='rhel6'
		fi
		
		echo "[$scriptName] Add repository"
		sudo sh -c "echo [CityFan] >> /etc/yum.repos.d/city-fan.repo" 
		sudo sh -c "echo name=City Fan Repo >> /etc/yum.repos.d/city-fan.repo"
		sudo sh -c "echo baseurl=http://nervion.us.es/city-fan/yum-repo/${versionID}/x86_64/ >> /etc/yum.repos.d/city-fan.repo"
		sudo sh -c "echo enabled=1 >> /etc/yum.repos.d/city-fan.repo"
		sudo sh -c "echo gpgcheck=0 >> /etc/yum.repos.d/city-fan.repo"
		echo			
		sudo cat /etc/yum.repos.d/city-fan.repo
		echo			
		echo "[$scriptName] Install software from repo"
		sudo yum clean all
		sudo yum install -y libcurl 
			
	else			
		echo "[$scriptName] CentOS/RHEL, specific version for CentOS not yet supported, try latest"
	fi
fi
 
echo "[$scriptName] --- end ---"
