#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Version not supplied. HALT!"
	exit 1
fi

if [ -z "$2" ]; then
	echo "$0 : Environment Definition not supplied. HALT!"
	exit 1
fi

if [ -z "$3" ]; then
	echo "$0 : List of Configuration Files not supplied. HALT!"
	exit 1
fi

if [ -z "$4" ]; then
	echo "$0 : Absolute Path of Configuration Files not supplied. HALT!"
	exit 1
fi

# Path is received as absolute, when processing source, read realtive (..) 
# while target is the absolute path passed.

# Process configuration file list
while read FILENAME
do
	# Detokenise the configuration files and only update if differnt
	./transform.sh ./detoken/$2 ..$4/$FILENAME
	./versionReplace.sh $4/$FILENAME $1

done < ./build/$3
