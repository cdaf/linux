#!/usr/bin/env bash
set -e
scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "$scriptName : Directory not supplied, pass as absolute path i.e. /etc/init.d/bonita. HALT!"
	exit 1
fi

# Check that Version has been passed
if [ -z "$2" ]; then
	echo "$scriptName : Version not supplied. HALT!"
	exit 1
fi

# Process all jar files in the directory
./versionDirectory.sh "$1" "$2" "*.jar"
