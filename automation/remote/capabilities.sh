#!/usr/bin/env bash

scriptName='capabilities.sh'

echo
echo "[$scriptName] --- start ---"
capability=$1
if [ -z "$capability" ]; then
	echo "[$scriptName] capability not supplied, provide listing only"
else
	echo "[$scriptName] capability : $capability"
	value=$2
	if [ -z "$value" ]; then
		echo "[$scriptName] capability supplied, but not value supplied, exiting with code 2"; exit 2
	else
		echo "[$scriptName] value      : $value"
	fi
fi

echo
echo "[$scriptName] System features"
test="`hostname -f 2>&1`"
if [ $? -ne 0 ]; then
	echo "[$scriptName]   hostname : $(hostname)"
else
	echo "[$scriptName]   hostname : $test"
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

# curl
test="`curl --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] curl             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] curl             : $test"
fi	

# Java version lists to standard error
test="`java -version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Java             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	IFS='"' read -ra ADDR <<< ${ADDR[2]}
	test=${ADDR[@]}
	echo "[$scriptName] Java             : $test"
fi	
if [[ "$capability" == 'java' ]]; then
	if [[ "$test" == *"$value"* ]]; then
		echo "[$scriptName]   Capability ($capability) test ($value) passed."
	else
		echo; echo "[$scriptName] Capability ($capability) does not equal $value, instead $test returned, exiting with error code 99"; echo; exit 99
	fi
fi		

test="`javac -version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Java Compiler    : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] Java Compiler    : $test"
fi	

# Ant version lists to standard error
test="`ant -version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Apache Ant       : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[3]}
	echo "[$scriptName] Apache Ant       : $test"
fi	

test=$(mvn -version 2>&1)
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Apache Maven     : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[2]}
	echo "[$scriptName] Apache Maven     : $test"
fi

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

# Python version lists to standard error
test="`python --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Python v2        : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "[$scriptName] Python v2        : ${ADDR[1]}"
fi	

# PIP version lists to standard error
test="`pip --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] PIP v2           : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] PIP v2           : $test"
fi	

# Python version lists to standard error
test="`python3 --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Python v3        : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] Python v3        : $test"
fi	

# PIP version lists to standard error
test="`pip3 --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] PIP              : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "[$scriptName] PIP v3           : ${ADDR[1]}"
fi	

# Ansible components
test=$(ansible-playbook --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "[$scriptName] Anisble playbook : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "[$scriptName] Ansible playbook : ${ADDR[1]}"
fi	

# Ruby
test="`ruby --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Ruby             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "[$scriptName] Ruby             : ${ADDR[1]}"
fi	

# Puppet
test="`puppet --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Puppet           : (not installed)"
else
	echo "[$scriptName] Puppet           : $test"
fi	

# NodeJS components
test=$(node --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "[$scriptName] NodeJS           : (not installed)"
else
	echo "[$scriptName] NodeJS           : $test"
fi	

# Node Package Manager
test=$(npm -version 2>/dev/null)
if [ -z "$test" ]; then
	echo "[$scriptName] NPM              : (not installed)"
else
	echo "[$scriptName] NPM              : $test"
fi	

# process manager for Node.js
test=$(pm2 --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "[$scriptName] PM2              : (not installed)"
else
	echo "[$scriptName] PM2              : $test"
fi	

# process manager for Node.js "nodemon reload, automatically"
test=$(nodemon --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "[$scriptName] NodeMon          : (not installed)"
else
	echo "[$scriptName] NodeMon          : $test"
fi	

# dotnet core
test=$(dotnet --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "[$scriptName] dotnet core      : (not installed)"
else
	echo "[$scriptName] dotnet core      : $test"
fi	

echo
echo "[$scriptName] --- end ---"
echo
