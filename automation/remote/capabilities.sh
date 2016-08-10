#!/usr/bin/env bash

scriptName='Capabilities.sh'

echo
echo "[$scriptName] : --- start ---"
echo
test=$(java --version 2> /dev/null)
if [ -n "$test" ]; then
	echo "[$scriptName] : Java version is $test"
else
	echo "[$scriptName] : Java not installed."
fi	

echo
test=$(ant --version 2> /dev/null)
if [ -n "$test" ]; then
	echo "[$scriptName] : Ant version is $test"
else
	echo "[$scriptName] : Ant not installed."
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
