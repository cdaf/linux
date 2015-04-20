#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Directory not supplied, pass as absolute path i.e. /etc/init.d/bonita. HALT!"
	exit 1
fi

# Check that Version has been passed
if [ -z "$2" ]; then
	echo "$0 : Version not supplied. HALT!"
	exit 1
fi

# Process all jar files in the directory
./versionDirectory.sh "$1" "$2" "*.jar"
