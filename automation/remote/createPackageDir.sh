#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Directory not supplied, pass as absolute path i.e. /opt/packages. HALT!"
	exit 1
fi

# Create the Directory
if [ -d "$1" ]; then
	echo "$0 : Directory $1 exists, no action required"
else
	echo "$0 : Create $1 on target host"
	mkdir $1
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : mkdir $1failed! Returned $exitCode"
		exit $exitCode
	fi
fi

