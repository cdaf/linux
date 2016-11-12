#!/usr/bin/env bash

scriptName='capabilities.sh'

echo
echo "[$scriptName] : --- start ---"
echo
# Java version lists to standard error
test="`java -version 2>&1`"
if [[ $test == *"command not found"* ]]; then
	echo "[$scriptName] : Java not installed."
else
	echo "[$scriptName] : $test"
fi	

test="`javac -version 2>&1`"
if [[ $test == *"command not found"* ]]; then
	echo "[$scriptName] : Java Compiler not installed."
else
	echo "[$scriptName] : $test"
fi	

# Ant version lists to standard error
test="`ant -version 2>&1`"
if [[ $test == *"command not found"* ]]; then
	echo "[$scriptName] : Ant not installed."
else
	echo "[$scriptName] : Ant version : $test"
fi	

test=$(mvn -version 2>/dev/null)
if [ -n "$test" ]; then
	echo "[$scriptName] : Maven version : $test"
else
	echo "[$scriptName] : Maven not installed."
fi

test=$(docker --version 2> /dev/null)
if [ -n "$test" ]; then
	echo "[$scriptName] : Docker version : $test"
else
	echo "[$scriptName] : Docker not installed."
fi	

# Python version lists to standard error
test="`python --version 2>&1`"
test=$(echo $test | grep 'Python 2.')
if [ -n "$test" ]; then
	IFS=' ' read -ra ADDR <<< $test
		test=${ADDR[1]}
	echo "[$scriptName] : Python version : $test"
else
	echo "[$scriptName] : Python not installed."
fi	

# PIP version lists to standard error
test="`pip --version 2>&1`"
test=$(echo $test | grep 'python ')
if [ -n "$test" ]; then
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] : PIP version : $test"
else
	echo "[$scriptName] : PIP not installed."
fi	

# Python version lists to standard error
test="`python3 --version 2>&1`"
test=$(echo $test | grep 'python3.')
if [ -n "$test" ]; then
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] : Python v3 version : $test"
else
	echo "[$scriptName] : Python v3 not installed."
fi	

# PIP version lists to standard error
test="`pip3 --version 2>&1`"
test=$(echo $test | grep 'python ')
if [ -n "$test" ]; then
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] : PIP v3 version : $test"
else
	echo "[$scriptName] : PIP v3 not installed."
fi	

# Ansible components
test=$(ansible-playbook --version 2> /dev/null)
if [ -n "$test" ]; then
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] : Anisble playbook version : $test"
else
	echo "[$scriptName] : Anisble playbook not installed."
fi	

echo
echo "[$scriptName] : --- end ---"
echo
