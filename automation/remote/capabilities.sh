#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "$0 : Version not passed. HALT!"
	exit 1
else
	VERSION=$1
fi

echo
echo "$0 : +--------------+"
echo "$0 : | Capabilities |"
echo "$0 : +--------------+"
echo
echo "$0 :   VERSION     : $VERSION"
echo
test=$(java --version 2> /dev/null)
if [ -z "$1" ]; then
	echo "$0 : Java version is $test"
else
	echo "$0 : Java not installed."
fi	

echo
test=$(ant --version 2> /dev/null)
if [ -z "$1" ]; then
	echo "$0 : Ant version is $test"
else
	echo "$0 : Ant not installed."
fi	
echo
test=$(docker --version 2> /dev/null)
if [ -z "$1" ]; then
	echo "$0 : Docker version is $test"
else
	echo "$0 : Docker not installed."
fi	
