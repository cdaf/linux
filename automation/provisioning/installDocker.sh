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

scriptName='installDocker.sh'

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
	install='canon'
	echo "[$scriptName]   install      : $install (default canon, choices canon or latest)"
else
	install=$1
	echo "[$scriptName]   install      : $install (choices canon, latest or a path to binary)"
fi


if [ -z "$2" ]; then
	startDaemon='no'
	echo "[$scriptName]   startDaemon  : $startDaemon (default, only applied to binary install)"
else
	startDaemon=$2
	echo "[$scriptName]   startDaemon  : $startDaemon (only applied to binary install)"
fi
check='yes'
if [ "$install" != 'canon' ] && [ "$install" != 'latest' ]; then # Install from binary media

	package=$(ls -1 $install/docker*.tgz)
	if [ -n "$package" ]; then
		# When running under vagranT, cannot extract from the replicated file share, so copy to 
		# local file system, then extract
		executeExpression "sudo cp $install/docker-latest.tgz /tmp"
		executeExpression 'cd /tmp'
		executeExpression 'tar -xvzf docker-latest.tgz'
		executeExpression 'sudo mv docker/* /usr/bin/'
		
		# When running under vagrant have found issues with starting daemon in provisioning mode
		# i.e. cannot connect to docker, even when user is a member of the docker group			
		if [ "$startDaemon" == 'yes' ] ; then
			executeExpression 'sudo docker daemon &'
		else
			check='no'
		fi
	else
		echo "[$scriptName] media directory supplied, but no docker zip file found, switching to canonical install..."
		install='canon'
	fi
fi

# If not binary install, or binary not found, install via repos 
if [ -z "$package" ]; then

	if [ "$centos" ]; then
	
		if [ "$install" == 'canon' ]; then

			if [ -f /etc/os-release ]; then 
				echo "[$scriptName] Install CentOS 7 Canonical docker.io ($install)"
				echo "[$scriptName] sudo yum check-update (not, a normal exit code is non zero)"
				sudo yum check-update 
				executeExpression "sudo yum install -y docker"
				executeExpression "sudo systemctl enable docker.service"
				executeExpression "sudo systemctl start docker.service"
				executeExpression "sudo systemctl status docker.service"
			else
				echo "[$scriptName] Install CentOS 6 from Docker repository"
				sudo sh -c "echo [dockerrepo] > /etc/yum.repos.d/docker.repo"
				sudo sh -c "echo name=Docker Repository >> /etc/yum.repos.d/docker.repo"
				sudo sh -c "echo baseurl=https://yum.dockerproject.org/repo/main/centos/6/ >> /etc/yum.repos.d/docker.repo"
				sudo sh -c "echo enabled=1 >> /etc/yum.repos.d/docker.repo"
				sudo sh -c "echo gpgcheck=1 >> /etc/yum.repos.d/docker.repo"
				sudo sh -c "echo gpgkey=https://yum.dockerproject.org/gpg >> /etc/yum.repos.d/docker.repo"
				echo			
				executeExpression "sudo cat /etc/yum.repos.d/docker.repo"
				echo			
				echo "[$scriptName] Install software from repo"
				executeExpression "sudo yum install -y docker-engine"
				executeExpression "sudo service docker start"
				executeExpression "sudo service docker status"
			fi

		else
			echo "[$scriptName] Only canonical for CentOS/RHEL supported"
		fi
		
	else # Debian

		if [ "$install" == 'canon' ]; then

			echo "[$scriptName] Install Ubuntu Canonical docker.io ($install)"
			executeExpression "sudo apt-get update"
			executeExpression "sudo apt-get install -y docker.io"

		else

			echo "[$scriptName] Specific version only supported for Ubuntu 14"
			echo "[$scriptName] Install latest from Docker ($install)"
			echo "[$scriptName] Add the new GPG key"
			executeExpression "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D"
	
			echo "[$scriptName] Update sources for 14.04"
			executeExpression "sudo sh -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" >> /etc/apt/sources.list.d/docker.list'"
			
			echo "[$scriptName] Update apt repository, purge and verify repository"
			executeExpression "sudo apt-get update"
			executeExpression "sudo apt-get purge lxc-docker"
			executeExpression "apt-cache policy docker-engine"
		
			echo "[$scriptName] Install the extras for this architecture linux-image-extra-$(uname -r)"
			executeExpression 'sudo apt-get install -y linux-image-extra-$(uname -r)'
	
			echo "[$scriptName] Docker document states apparmor needs to be installed"
			executeExpression "sudo apt-get install -y apparmor"
	
			echo "[$scriptName] Docker document states apparmor needs to be installed"
			executeExpression "sudo apt-get install -y docker-engine"
			
		fi
		
	fi
fi

if [ "$check" == 'yes' ] ; then
	echo "[$scriptName] Pause for Docker to start, the list version details..."
	sleep 5
	executeExpression "sudo docker version"
else
	echo "[$scriptName] Do not check docker version as binary install with \$startDaemon set to $startDaemon"
fi
 
echo "[$scriptName] --- end ---"
