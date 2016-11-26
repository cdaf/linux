#!/usr/bin/env bash

scriptName='capabilities.sh'

echo
echo "[$scriptName] --- start ---"
echo
echo "[$scriptName] System features"
echo "[$scriptName]   hostname : $(hostname -f)"
IFS=$'\n'
for ip in `ip a | grep "inet "`; do
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
	test=${ADDR[2]}
	echo "[$scriptName] Java version : $test"
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
