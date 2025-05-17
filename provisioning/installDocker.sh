#!/usr/bin/env bash

# Install with defaults
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/installDocker.sh | bash -

# Install explicit version
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/installDocker.sh | bash -s -- '26.1.3'

function executeRetry {
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

if [ -z "$3" ]; then
	version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name)
	version=${version##*v}
	version=${version%\"*}
	echo "[$scriptName]   compose      : $version (latest)"
else
	echo "[$scriptName]   compose      : $version"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami       : $(whoami)"
else
	echo "[$scriptName]   whoami       : $(whoami) (elevation not required)"
fi

echo
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

check='yes'
if [ "$install" != 'canon' ] && [ "$install" != 'latest' ]; then # Install from binary media

	package=$(ls -1 $install/docker*.tgz)
	if [ ! -z "$package" ]; then
		# When running under vagranT, cannot extract from the replicated file share, so copy to 
		# local file system, then extract
		executeRetry "${elevate} cp $install/docker-latest.tgz /tmp"
		executeRetry 'cd /tmp'
		executeRetry 'tar -xvzf docker-latest.tgz'
		executeRetry "${elevate} mv docker/* /usr/bin/"
		
		# When running under vagrant have found issues with starting daemon in provisioning mode
		# i.e. cannot connect to docker, even when user is a member of the docker group			
		if [ "$startDaemon" == 'yes' ] ; then
			executeRetry "${elevate} docker daemon &"
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

		if [ -f '/etc/centos-release' ]; then
			read -r -a array <<< $(cat /etc/centos-release)
			echo "[$scriptName]   Version  : ${array[5]}"
		else
			if [ -f '/etc/redhat-release' ]; then
				read -r -a array <<< $(cat /etc/redhat-release)
				echo "[$scriptName]   Version  : ${array[5]}"
			else
				echo "[$scriptName] Unknown Fedora distribution! Exiting"
				exit 4432
			fi
		fi
		IFS='.' read -r -a array <<< "${array[5]}"
		fVersion=$(echo "${array[0]}")

		if [ -z "$centos" ]; then # Red Hat Enterprise Linux (RHEL)
		    install='latest'
			echo; echo "[$scriptName] For RHEL, only $install supported"
		    executeIgnore "${elevate} subscription-manager repos --enable=rhel-${fVersion}-server-extras-rpms" # Ignore if already installed
		fi

		if [ "$install" == 'canon' ]; then

			echo "[$scriptName] Install Canonical docker.io ($install)"
			if [ "${elevate}" ]; then
				echo "[$scriptName] ${elevate} yum check-update (note: a normal exit code is non zero)"
				sudo yum check-update
			else
				echo "[$scriptName] yum check-update (note: a normal exit code is non zero)"
				yum check-update
			fi
			executeRetry "${elevate} yum install -y docker"
			executeRetry "${elevate} systemctl enable docker.service"
			executeRetry "${elevate} systemctl start docker.service"
			executeRetry "${elevate} systemctl status docker.service --no-pager"

		else
			executeRetry "${elevate} yum install -y yum-utils device-mapper-persistent-data lvm2"
			executeRetry "${elevate} yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
			executeRetry "${elevate} yum install -y --nobest docker-ce"
			executeRetry "${elevate} service docker start"
			executeRetry "systemctl --no-pager status docker"
		fi
		
	else # Debian

		echo
		echo "[$scriptName] Check that APT is available"
		dailyUpdate=$(ps -ef | grep  /usr/lib/apt/apt.systemd.daily | grep -v grep)
		if [ ! -z "${dailyUpdate}" ]; then
			echo
			echo "[$scriptName] ${dailyUpdate}"
			IFS=' ' read -ra ADDR <<< $dailyUpdate
			echo
			executeRetry "${elevate} kill -9 ${ADDR[1]}"
			executeRetry "sleep 5"
		fi

		if [ "$install" == 'canon' ]; then

			echo "[$scriptName] Install Ubuntu Canonical docker.io ($install)"
			executeRetry "${elevate} apt-get update"
			executeRetry "${elevate} apt-get install -y docker.io"

		else # latest

			echo "[$scriptName] Install Latest Community Edition for Ubuntu"
			executeIgnore "${elevate} apt-get -y remove docker*"
			executeIgnore "${elevate} apt-get purge -y docker-engine docker docker.io docker-ce"
			executeIgnore "${elevate} apt-get autoremove -y --purge docker-engine docker docker.io docker-ce"
			executeRetry "${elevate} apt-get update"
			executeRetry "${elevate} apt-get install -y apt-transport-https ca-certificates curl software-properties-common"
			executeRetry "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${elevate} apt-key add -"
			executeRetry "${elevate} apt-key fingerprint 0EBFCD88"
			executeRetry "${elevate} add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable'"
			executeRetry "${elevate} apt-get update"
			executeRetry "${elevate} apt-get install -y docker-ce"
			executeRetry "docker --version"
		fi
	fi
fi

executeRetry "${elevate} curl -f -sL 'https://github.com/docker/compose/releases/download/$version/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose"
executeRetry "${elevate} chmod +x /usr/local/bin/docker-compose"

if [ "$check" == 'yes' ] ; then
	echo; echo "[$scriptName] Pause for Docker to start, the list version details..."
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
