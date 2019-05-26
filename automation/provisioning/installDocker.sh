#!/usr/bin/env bash

function executeExpression {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval "$1"
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max} after 20 second pause ..."
				sleep 20
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		else
			success='yes'
		fi
	done
}  

function executeIgnore {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Warning: Returned $exitCode continuing ..."
	fi
	return $exitCode
}

scriptName='installDocker.sh'

echo "[$scriptName] --- start ---"
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

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami       : $(whoami)"
else
	echo "[$scriptName]   whoami       : $(whoami) (elevation not required)"
fi

test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] yum not found, assuming Debian/Ubuntu, using apt-get"
else
	fedora='yes'
	centos=$(cat /etc/redhat-release | grep CentOS)
	if [ -z "$centos" ]; then
		echo "[$scriptName] Red Hat Enterprise Linux"
	else
		echo "[$scriptName] CentOS Linux"
	fi
fi
echo

check='yes'
if [ "$install" != 'canon' ] && [ "$install" != 'latest' ]; then # Install from binary media

	package=$(ls -1 $install/docker*.tgz)
	if [ -n "$package" ]; then
		# When running under vagranT, cannot extract from the replicated file share, so copy to 
		# local file system, then extract
		executeExpression "$elevate cp $install/docker-latest.tgz /tmp"
		executeExpression 'cd /tmp'
		executeExpression 'tar -xvzf docker-latest.tgz'
		executeExpression '$elevate mv docker/* /usr/bin/'
		
		# When running under vagrant have found issues with starting daemon in provisioning mode
		# i.e. cannot connect to docker, even when user is a member of the docker group			
		if [ "$startDaemon" == 'yes' ] ; then
			executeExpression '$elevate docker daemon &'
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

	if [ "$fedora" ]; then

		if [ -z "$centos" ]; then # Red Hat Enterprise Linux (RHEL)
		    install='latest'
			echo "[$scriptName] For RHEL, only $install supported"
		    executeIgnore "$elevate subscription-manager repos --enable=rhel-7-server-extras-rpms" # Ignore if already installed
		fi

		if [ "$install" == 'canon' ]; then

			if [ -f /etc/os-release ]; then 
				echo "[$scriptName] Install CentOS 7 Canonical docker.io ($install)"
				if [ "$elevate" ]; then
					echo "[$scriptName] sudo yum check-update (note: a normal exit code is non zero)"
					sudo yum check-update
				else
					echo "[$scriptName] yum check-update (note: a normal exit code is non zero)"
					yum check-update
				fi
				executeExpression "$elevate yum install -y docker docker-compose"
				executeExpression "$elevate systemctl enable docker.service"
				executeExpression "$elevate systemctl start docker.service"
				executeExpression "$elevate systemctl status docker.service"
			else
				echo "[$scriptName] Install CentOS 6 from Docker repository"
				if [ "$elevate" ]; then
					sudo sh -c "echo [dockerrepo] > /etc/yum.repos.d/docker.repo"
					sudo sh -c "echo name=Docker Repository >> /etc/yum.repos.d/docker.repo"
					sudo sh -c "echo baseurl=https://yum.dockerproject.org/repo/main/centos/6/ >> /etc/yum.repos.d/docker.repo"
					sudo sh -c "echo enabled=1 >> /etc/yum.repos.d/docker.repo"
					sudo sh -c "echo gpgcheck=1 >> /etc/yum.repos.d/docker.repo"
					sudo sh -c "echo gpgkey=https://yum.dockerproject.org/gpg >> /etc/yum.repos.d/docker.repo"
				else
					sh -c "echo [dockerrepo] > /etc/yum.repos.d/docker.repo"
					sh -c "echo name=Docker Repository >> /etc/yum.repos.d/docker.repo"
					sh -c "echo baseurl=https://yum.dockerproject.org/repo/main/centos/6/ >> /etc/yum.repos.d/docker.repo"
					sh -c "echo enabled=1 >> /etc/yum.repos.d/docker.repo"
					sh -c "echo gpgcheck=1 >> /etc/yum.repos.d/docker.repo"
					sh -c "echo gpgkey=https://yum.dockerproject.org/gpg >> /etc/yum.repos.d/docker.repo"
				fi
				echo			
				executeExpression "$elevate cat /etc/yum.repos.d/docker.repo"
				echo			
				echo "[$scriptName] Install software from repo"
				executeExpression "$elevate yum install -y docker-engine docker-compose"
				executeExpression "$elevate service docker start"
				executeExpression "$elevate service docker status"
			fi

		else
			executeExpression "$elevate yum install -y yum-utils device-mapper-persistent-data lvm2"
			executeExpression "$elevate yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
			executeExpression "$elevate yum install -y docker-ce"
			executeExpression "$elevate service docker start"
			executeExpression "$elevate service docker status"
		fi
		
	else # Debian

		echo
		echo "[$scriptName] Check that APT is available"
		dailyUpdate=$(ps -ef | grep  /usr/lib/apt/apt.systemd.daily | grep -v grep)
		if [ -n "${dailyUpdate}" ]; then
			echo
			echo "[$scriptName] ${dailyUpdate}"
			IFS=' ' read -ra ADDR <<< $dailyUpdate
			echo
			executeExpression "$elevate kill -9 ${ADDR[1]}"
			executeExpression "sleep 5"
		fi

		if [ "$install" == 'canon' ]; then

			echo "[$scriptName] Install Ubuntu Canonical docker.io ($install)"
			executeExpression "$elevate apt-get update"
			executeExpression "$elevate apt-get install -y docker.io docker-compose"

		else # latest

			echo "[$scriptName] Install Latest Community Edition for Ubuntu"
			executeIgnore "$elevate apt-get -y remove docker*"
			executeIgnore "$elevate apt-get purge -y docker-engine docker docker.io docker-ce"
			executeIgnore "$elevate apt-get autoremove -y --purge docker-engine docker docker.io docker-ce"
			executeExpression "$elevate apt-get update"
			executeExpression "$elevate apt-get install -y apt-transport-https ca-certificates curl software-properties-common"
			executeExpression "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
			executeExpression "$elevate apt-key fingerprint 0EBFCD88"
			executeExpression "$elevate add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable'"
			executeExpression "$elevate apt-get update"
			executeExpression "$elevate apt-get install -y docker-ce"
			executeExpression "docker --version"
 
			executeExpression "sudo curl -sL 'https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose"
			executeExpression "$elevate chmod +x /usr/local/bin/docker-compose"
			executeExpression "docker-compose --version"			
		fi
		
	fi
fi

if [ "$check" == 'yes' ] ; then
	echo "[$scriptName] Pause for Docker to start, the list version details..."
	sleep 5
	echo
	test=$(docker --version 2>&1)
	if [[ "$test" == *"not found"* ]]; then
		echo "[$scriptName] Docker           : (not installed)"
	else
		IFS=' ' read -ra ADDR <<< $test
		IFS=',' read -ra ADDR <<< ${ADDR[2]}
		echo "[$scriptName] Docker           : ${ADDR[0]}"
	fi
	
	test=$(docker-compose --version 2>&1)
	if [[ "$test" == *"not found"* ]]; then
		echo "[$scriptName] Docker compose   : (not installed)"
	else
		IFS=' ' read -ra ADDR <<< $test
		IFS=',' read -ra ADDR <<< ${ADDR[2]}
		echo "[$scriptName] Docker compose   : ${ADDR[0]}"
	fi
else
	echo "[$scriptName] Do not check docker version as binary install with \$startDaemon set to $startDaemon"
fi
echo 
echo "[$scriptName] --- end ---"
