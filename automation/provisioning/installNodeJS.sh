#!/usr/bin/env bash

function executeExpression {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval $1
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		else
			success='yes'
		fi
	done
}

function executeYumCheck {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval $1
		exitCode=$?
		# Exit 0 and 100 are both success
		if [ "$exitCode" == "100" ] || [ "$exitCode" == "0" ]; then
			success='yes'
		else
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		fi
	done
}

scriptName='installNodeJS.sh'
echo
echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	echo "[$scriptName]   version        : (not supplied, will install canonical)"
else
	echo "[$scriptName]   version        : $version"
	systemWide=$2
	if [ -z "$systemWide" ]; then
		systemWide='yes'
		echo "[$scriptName]   systemWide : $systemWide (default)"
	else
		if [ "$systemWide" == 'yes' ] || [ "$systemWide" == 'no' ]; then
			echo "[$scriptName]   systemWide : $systemWide"
		else
			echo "[$scriptName] Expecting yes or no, exiting with error code 1"; exit 1
		fi
	fi

	mediaCache="$3"
	if [ -z "$mediaCache" ]; then
		mediaCache='/_provision'
		echo "[$scriptName]   mediaCache : $mediaCache (default)"
	else
		echo "[$scriptName]   mediaCache : $mediaCache"
	fi
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami         : $(whoami)"
else
	echo "[$scriptName]   whoami         : $(whoami) (elevation not required)"
fi

if [ -z "$version" ]; then
	test="`yum --version 2>&1`"
	if [[ "$test" == *"not found"* ]]; then
		echo "[$scriptName] Debian/Ubuntu, update repositories using apt-get"
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
		
		echo "[$scriptName] $elevate apt-get update"
		echo
		timeout=3
		count=0
		while [ ${count} -lt ${timeout} ]; do
			$elevate apt-get update
			exitCode=$?
			if [ "$exitCode" != "0" ]; then
		   	    ((count++))
				echo "[$scriptName] apt-get sources update failed with exit code $exitCode, retry ${count}/${timeout} "
			else
				count=${timeout}
			fi
		done
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] apt-get sources failed to update after ${timeout} tries, will try with existing cache ..."
		fi
		echo
		executeExpression "$elevate apt-get install -y nodejs npm curl"
		
		test="`node -v 2>&1`"
		if [[ "$test" == *"not found"* ]]; then
			echo "[$scriptName] Node not found, create symlink to NodeJS."
			executeExpression "ln -s /usr/bin/nodejs /usr/bin/node"
			test="`node -v 2>&1`"
			if [[ "$test" == *"not found"* ]]; then
				echo "[$scriptName] Install Error! Node verification failed."
				exit 939
			fi
		fi
		

	else
		echo "[$scriptName] CentOS/RHEL, update repositories using yum"
		executeYumCheck "$elevate yum check-update"
	
		echo
		executeExpression "$elevate yum install -y epel-release curl sudo gcc-c++ make"
		echo;echo "[$scriptName] Aligning to Ubuntu 16.04 canonical version, i.e. v4"
		executeExpression "curl --silent --location https://rpm.nodesource.com/setup_4.x | $elevate bash -"
		executeExpression "$elevate yum install -y nodejs"

	fi
	echo; echo "[$scriptName] Verify Node Package Manager (NPM) version"
	executeExpression "npm --version"

else

	runtime="node-v${version}-linux-x64"
	mediaFullPath="${mediaCache}/${runtime}.tar.gz"
	
	# Check for media
	if [ -f "$mediaFullPath" ]; then
		echo "[$scriptName] Media found $mediaFullPath"
	else
		echo "[$scriptName] Media not found, attempting download"
		if [ ! -d "$mediaCache" ]; then
			executeExpression "sudo mkdir -p $mediaCache"
		fi
		executeExpression "sudo curl -s -o $mediaFullPath http://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.gz"
	fi
	
	if [ "$systemWide" == 'yes' ]; then
	
		cd $mediaCache
		executeExpression "sudo tar -xzf node-v* -C /opt"
	
		# Set the environment settings (requires elevation), replace if existing
		echo "[$scriptName] echo export PATH=\"/opt/${runtime}/bin:$PATH\" > nodejs.sh"
		echo export PATH=\"/opt/${runtime}/bin:$PATH\" > nodejs.sh
	
		executeExpression "chmod +x nodejs.sh"
		executeExpression "sudo mv -v nodejs.sh /etc/profile.d/"
	
		# Execute the script to set the variable 
		executeExpression "source /etc/profile.d/nodejs.sh"
	
	else
	
		executeExpression "curl https://raw.githubusercontent.com/creationix/nvm/v0.13.1/install.sh | bash"
		executeExpression "source ~/.bash_profile"
		executeExpression "nvm install v${version}"
		executeExpression "nvm alias default v${version}"
	fi
fi

echo; echo "[$scriptName] Verify Node version"

executeExpression "node --version"

echo "[$scriptName] --- end ---"
