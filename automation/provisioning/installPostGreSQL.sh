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
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "100" ]; then
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

scriptName='installPostGreSQL.sh'

echo "[$scriptName] --- start ---"
prefix="$1"
if [ -z "$prefix" ]; then
	echo "[$scriptName]   password : blank"
else
	echo "[$scriptName]   password : ****************"
fi

version="$2"
if [ -z "$version" ]; then
	version='canon'
	install='postgresql'
	echo "[$scriptName]   version  : $version (default, $install)"
else
	install="postgresql-$version"
	echo "[$scriptName]   version  : $version ($install)"
fi
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami   : $(whoami)"
else
	echo "[$scriptName]   whoami   : $(whoami) (elevation not required)"
fi

echo
# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution"
test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Ubuntu/Debian, update repositories using apt-get"
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
	
	executeExpression "$elevate apt-get update"
	executeExpression "$elevate apt-get install -y $install"
	echo
	executeExpression "$elevate service postgresql restart"

else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	executeYumCheck "$elevate yum check-update"
	executeExpression "$elevate yum install -y postgresql-server postgresql-contrib"
	executeExpression "$elevate sudo postgresql-setup initdb"
	fileName='/var/lib/pgsql/data/pg_hba.conf'
	name='ident'
	value='md5'
	executeExpression "$elevate sed -i 's^${name}^${value}^g' ${fileName}"
	executeExpression "$elevate cat ${fileName}"
	executeExpression "$elevate sudo systemctl start postgresql"
	executeExpression "$elevate sudo systemctl enable postgresql"
fi

echo "[$scriptName] --- end ---"

