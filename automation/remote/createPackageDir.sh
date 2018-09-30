#!/usr/bin/env bash
set -e

scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "$scriptName : Directory not supplied, pass as absolute path i.e. /opt/packages. HALT!"
	exit 1
fi

# Create the Directory
if [ -d "$1" ]; then
	echo "$scriptName : Directory $1 exists, no action required"
else
	echo "$scriptName : Create $1 on target host"
	mkdir $1
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$scriptName : mkdir $1failed! Returned $exitCode"
		exit $exitCode
	fi
fi

