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
echo "[$scriptName]   hostname : $(hostname -f)"
IFS=$'\n'
if [ -f '/sbin/ip' ]; then
	ipList=$(/sbin/ip a | grep "inet ")
else
	$(ip a | grep "inet ")
fi
for ip in $ipList; do
	IFS=' ' read -ra ADDR <<< $ip
	echo "[$scriptName]         ip : ${ADDR[1]}"
done

echo
# Java version lists to standard error
test="`java -version 2>&1`"
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] Java not installed."
else
	IFS=' ' read -ra ADDR <<< $test
	IFS='"' read -ra ADDR <<< ${ADDR[2]}
	test=${ADDR[@]}
	echo "[$scriptName] Java version : $test"
fi	
if [[ "$capability" == 'java' ]]; then
	if [[ "$test" == *"$value"* ]]; then
		echo "[$scriptName]   Capability ($capability) test ($value) passed."
	else
		echo; echo "[$scriptName] Capability ($capability) does not equal $value, instead $test returned, exiting with error code 99"; echo; exit 99
	fi
fi		

test="`javac -version 2>&1`"
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] Java Compiler not installed."
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] Java Compiler version : $test"
fi	

# Ant version lists to standard error
test="`ant -version 2>&1`"
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] Ant not installed."
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[3]}
	echo "[$scriptName] Ant version : $test"
fi	

test=$(mvn -version 2>&1)
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] Maven not installed."
else
	echo "[$scriptName] Maven version : $test"
fi

test=$(docker --version 2>&1)
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] Docker not installed."
else
	echo "[$scriptName] Docker version : $test"
fi	

# Python version lists to standard error
test="`python --version 2>&1`"
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] Python v2 not installed."
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] Python v2 version : $test"
fi	

# PIP version lists to standard error
test="`pip --version 2>&1`"
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] PIP v2 not installed."
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] PIP v2 version : $test"
fi	

# Python version lists to standard error
test="`python3 --version 2>&1`"
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] Python v3 not installed."
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] Python v3 version : $test"
fi	

# PIP version lists to standard error
test="`pip3 --version 2>&1`"
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] PIP v3 not installed."
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] PIP v3 version : $test"
fi	

# Ansible components
test=$(ansible-playbook --version 2>&1)
if [[ $test == *"not found"* ]]; then
	echo "[$scriptName] Anisble playbook not installed."
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] Anisble playbook version : $test"
fi	

echo
echo "[$scriptName] --- end ---"
echo
