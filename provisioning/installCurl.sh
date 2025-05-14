#!/usr/bin/env bash
scriptName='curl.sh'

echo "[$scriptName] --- start ---"
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
	version='latest'
	echo "[$scriptName]   version     : $version (default apt)"
else
	version=$1
	echo "[$scriptName]   version     : $version"
fi

echo "[$scriptName] Current version"
curl -V

if [ "$centos" ]; then

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

else # Debian

		echo "[$scriptName] Install $version on Ubuntu"
	if [ "$version" == 'latest' ]; then
		version='7.48.0'		
		echo "[$scriptName] latest not supported for Ubuntu 14.04, set to $version"
	fi			
	
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
 
echo "[$scriptName] --- end ---"
