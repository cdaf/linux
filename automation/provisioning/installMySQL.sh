#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ $exitCode -ne 0 ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='installMySQL.sh'

echo "[$scriptName] --- start ---"
password="$1"
if [ -z "$password" ]; then
	echo "[$scriptName]   password : (not supplied will not be set)"
else
	echo "[$scriptName]   password : ****************"
fi

version="$2"
if [ -z "$version" ]; then
	version='5.7'
	install='mysql-server'
	echo "[$scriptName]   version  : $version (default, $install)"
else
	install="mysql-server-$version"
	echo "[$scriptName]   version  : $version ($install)"
fi

bind="$3"
if [ -z "$bind" ]; then
	echo "[$scriptName]   bind     : (not supplied, will bind to all)"
else
	echo "[$scriptName]   bind     : $bind"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami   : $(whoami)"
else
	echo "[$scriptName]   whoami   : $(whoami) (elevation not required)"
fi

test=$(mysql -V 2>&1)
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName]   MySQL    : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "[$scriptName]   MySQL    : ${ADDR[4]//,}"
fi	

# Install from global repositories only supporting CentOS and Ubuntu
echo "[$scriptName] Determine distribution"
test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	ubuntu='yes'
	echo "[$scriptName] Ubuntu/Debian, update repositories using apt-get"
	echo "[$scriptName] $elevate apt-get update"; echo
	timeout=3
	count=0
	while [ ${count} -lt ${timeout} ]; do
		if [[ $elevate == 'sudo' ]]; then
			sudo apt-get update
		else
			apt-get update
		fi
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
	   	    ((count++))
			echo "[$scriptName] apt-get sources update failed with exit code $exitCode, retry ${count}/${timeout} "
		else
			count=${timeout}
		fi
	done
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] apt-get sources failed to update after ${timeout} tries."
		echo "[$scriptName] Exiting with error code ${exitCode}"
		exit $exitCode
	fi
	# debconf-utils allows the passing of answer values
	executeExpression '$elevate apt-get install -y debconf-utils'
	echo "[$scriptName] Load installer responses"
	echo "[$scriptName]   $elevate debconf-set-selections <<< \"$install mysql-server/root_password password \$password\""
	echo "[$scriptName]   $elevate debconf-set-selections <<< \"$install  mysql-server/root_password_again password \$password\""
	if [[ $elevate == 'sudo' ]]; then
		sudo debconf-set-selections <<< "$install mysql-server/root_password password $password"
		sudo debconf-set-selections <<< "$install mysql-server/root_password_again password $password"
		sudo apt-get install -y $install
	else
		debconf-set-selections <<< "$install mysql-server/root_password password $password"
		debconf-set-selections <<< "$install mysql-server/root_password_again password $password"
		apt-get install -y $install
	fi
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ $exitCode -ne 0 ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
	
else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	echo "[$scriptName] $elevate yum check-update"
	echo
	timeout=3
	count=0
	while [ $count -lt $timeout ]; do
		# A "normal" exit code is 100, so cannot use executeExpression
		if [[ $elevate == 'sudo' ]]; then
			sudo yum check-update
		else
			yum check-update
		fi
		exitCode=$?
		if [ $exitCode -eq 0 ] || [ $exitCode -eq 100 ]; then
			echo "[$scriptName] Exit 0 and 100 are both success, setting exitCode (${exitCode}) to 0 "
			exitCode=0
			count=${timeout}
		else
	   	    ((count++))
			echo "[$scriptName] yum sources update failed with exit code $exitCode, retry ${count}/${timeout} "
		fi
	done
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] apt-get sources failed to update after ${timeout} tries."
		echo "[$scriptName] Exiting with error code ${exitCode}"
		exit $exitCode
	fi
	echo
	
	executeExpression "$elevate yum install -y mariadb-server mariadb"
	executeExpression "$elevate iptables -I INPUT -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT"
	executeExpression "$elevate iptables -I OUTPUT -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT"
	executeExpression "$elevate systemctl enable mariadb.service"
	executeExpression "$elevate systemctl start mariadb.service"

fi

test=$(mysql -V 2>&1)
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] MySQL      : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "[$scriptName] MySQL      : ${ADDR[4]//,}"
fi

if [ ! -z "$bind" ]; then
	if [[ "$ubuntu" == 'yes' ]]; then
		confFile='/etc/mysql/mysql.conf.d/mysqld.cnf'
	else
		confFile='/etc/my.cnf'
	fi

	# remove previous backup if exists, the following sed will create a new back-up
	executeExpression "cp ${confFile} ."
	if [ -f "mysqld.cnf.bak" ]; then
		executeExpression "rm mysqld.cnf.bak"
	fi
	
	executeExpression "sed -i.bak '/bind-address/d' mysqld.cnf"
	echo "[$scriptName] Add bind ${confFile} "; echo
	if [[ "$ubuntu" == 'yes' ]]; then
		echo "bind-address = $bind" > ${confFile}
	else
		token='[mysqld]'
		value="[mysqld]\nbind-address = $bind"
		sed -i -- "s^$token^$value^g" ${confFile}
	fi
	
	echo; echo "[$scriptName] List any differences ..."; echo
	diff --suppress-common-lines --side-by-side mysqld.cnf mysqld.cnf.bak
	
	if [ $? -ne 0 ]; then
		echo "[$scriptName] Configuration has changed, restart MqSQL"; echo
		executeExpression "$elevate cp -f mysqld.cnf ${confFile}"
		executeExpression "$elevate service mysql restart"
	else
		echo "[$scriptName] Configuration has not changed, restart not required"; echo
	fi
else
	if [ ! -z "$password" ]; then
		echo "[$scriptName] Test connection"
		executeExpression 'mysql -u root -p$password -e "show databases"'
	fi
fi	

echo "[$scriptName] --- end ---"
