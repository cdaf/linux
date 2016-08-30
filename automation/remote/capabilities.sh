#!/usr/bin/env bash

scriptName='Capabilities.sh'

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

echo
test="`javac -version 2>&1`"
if [[ $test == *"command not found"* ]]; then
	echo "[$scriptName] : Java Compiler not installed."
else
	echo "[$scriptName] : $test"
fi	

echo
# Ant version lists to standard error
test="`ant -version 2>&1`"
if [[ $test == *"command not found"* ]]; then
	echo "[$scriptName] : Ant not installed."
else
	echo "[$scriptName] : Ant version is $test"
fi	

echo
test=$(mvn -version 2>/dev/null)
if [ -n "$test" ]; then
	echo "[$scriptName] : Maven version is $test"
else
	echo "[$scriptName] : Maven not installed."
fi

echo
test=$(docker --version 2> /dev/null)
if [ -n "$test" ]; then
	echo "[$scriptName] : Docker version is $test"
else
	echo "[$scriptName] : Docker not installed."
fi	

echo
echo "[$scriptName] : --- end ---"
echo
