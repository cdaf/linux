#!/usr/bin/env bash

scriptName='capabilities.sh'

echo; echo "[$scriptName] --- start ---"
AUTOMATIONROOT="$(dirname $( cd "$(dirname "$0")" ; pwd -P ))"
if [ -f "$AUTOMATIONROOT/CDAF.linux" ]; then
	productVersion=$(cat "$AUTOMATIONROOT/CDAF.linux" | grep productVersion)
	IFS='=' read -ra ADDR <<< $productVersion
	echo "[$scriptName]   CDAF     : ${ADDR[1]}"
fi

test="`hostname -f 2>&1`"
if [ $? -ne 0 ]; then
	echo "[$scriptName]   hostname : $(hostname)"
else
	echo "[$scriptName]   hostname : $test"
fi

echo "[$scriptName]   pwd      : $(pwd)"
echo "[$scriptName]   whoami   : $(whoami)"

echo
if [ -f '/etc/centos-release' ]; then
	echo "[$scriptName]   distro   : $(cat /etc/centos-release)"
else
	if [ -f '/etc/redhat-release' ]; then
		echo "[$scriptName]   distro   : $(cat /etc/redhat-release)"
	else
		test="`lsb_release --all 2>&1`"
		if [[ "$test" == *"not found"* ]]; then
			if [ -f /etc/issue ]; then
				echo "[$scriptName]   distro   : $(cat /etc/issue)"
			else
				echo "[$scriptName]   distro   : $(uname -a)"
			fi
		else
			while IFS= read -r line; do
				if [[ "$line" == *"Description"* ]]; then
					IFS=' ' read -ra ADDR <<< $line
					echo "[$scriptName]   distro   : ${ADDR[1]} ${ADDR[2]}"
				fi
			done <<< "$test"
		fi	
	fi
fi

IFS=$'\n'
test="`ip a 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	test="`ifconfig 2>&1`"
	if [[ "$test" == *"not found"* ]]; then
		test="`ipconfig 2>&1`" # MING
		if [[ "$test" == *"not found"* ]]; then
			echo "[$scriptName]         ip : $(hostname -I)" # inside a container
		else
			ipconfig | grep IPv4
		fi
	else
		echo "[$scriptName]         ip : $test"
	fi
else
	test="`ip a | grep 'inet ' 2>&1`"
	for ip in $test; do
		IFS=' ' read -ra ADDR <<< $ip
		echo "[$scriptName]         ip : ${ADDR[1]}"
	done
fi
echo

if [ -f '/home/vagrant/linux-master/automation/CDAF.linux' ]; then
	test=$(cat /home/vagrant/linux-master/automation/CDAF.linux | grep productVersion)
	IFS='=' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] CDAF Box Version : $test"
fi

echo "[$scriptName] List 3rd party components"; echo

test="`git --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  Git              : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[2]}
	echo "  Git              : $test"
fi	

test="`curl --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  curl             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "  curl             : $test"
fi	

# Java version lists to standard error
test="`java -version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  Java             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	IFS='"' read -ra ADDR <<< ${ADDR[2]}
	echo "  Java             : $(echo -e "${ADDR[@]}" | tr -d '[[:space:]]')"
fi	

test="`javac -version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  Java Compiler    : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "  Java Compiler    : $test"
fi	

# Ant version lists to standard error
test="`ant -version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  Apache Ant       : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[3]}
	echo "  Apache Ant       : $test"
fi	

test=$(mvn -version 2>&1)
if [[ "$test" == *"not found"* ]]; then
	echo "  Apache Maven     : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[2]}
	echo "  Apache Maven     : $test"
fi

test=$(docker --version 2>&1)
if [[ "$test" == *"not found"* ]]; then
	echo "  Docker           : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	IFS=',' read -ra ADDR <<< ${ADDR[2]}
	echo "  Docker           : ${ADDR[0]}"
fi

test=$(docker-compose --version 2>&1)
if [[ "$test" == *"not found"* ]]; then
	echo "  Docker compose   : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	IFS=',' read -ra ADDR <<< ${ADDR[2]}
	echo "  Docker compose   : ${ADDR[0]}"
fi

# Python version lists to standard error
test="`python --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  Python v2        : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  Python v2        : ${ADDR[1]}"
fi	

# PIP version lists to standard error
test="`pip --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  PIP v2           : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "  PIP v2           : $test"
fi	

# Python version lists to standard error
test="`python3 --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  Python v3        : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "  Python v3        : $test"
fi	

# PIP version lists to standard error
test="`pip3 --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  PIP              : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  PIP v3           : ${ADDR[1]}"
fi	

# Ansible components
test=$(ansible-playbook --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  Anisble playbook : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  Ansible playbook : ${ADDR[1]}"
fi	

# Ruby
test="`ruby --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  Ruby             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  Ruby             : ${ADDR[1]}"
fi	

# Puppet
test="`puppet --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "  Puppet           : (not installed)"
else
	echo "  Puppet           : $test"
fi	

# NodeJS components
test=$(node --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  NodeJS           : (not installed)"
else
	echo "  NodeJS           : $test"
fi	

# Node Package Manager
test=$(npm -version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  NPM              : (not installed)"
else
	echo "  NPM              : $test"
fi	

# process manager for Node.js
test=$(pm2 --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  PM2              : (not installed)"
else
	echo "  PM2              : $test"
fi	

# process manager for Node.js "nodemon reload, automatically"
test=$(nodemon --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  NodeMon          : (not installed)"
else
	echo "  NodeMon          : $test"
fi	

# dotnet core
test=$(dotnet --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  dotnet core      : (not installed)"
else
	echo "  dotnet core      : $test"
fi	

echo; echo "[$scriptName] --- end ---"; echo
