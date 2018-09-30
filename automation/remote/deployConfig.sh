#!/usr/bin/env bash
set -e
scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "$scriptName : Version not supplied. HALT!"
	exit 1
fi

if [ -z "$2" ]; then
	echo "$scriptName : Environment Definition not supplied. HALT!"
	exit 1
fi

if [ -z "$3" ]; then
	echo "$scriptName : List of Configuration Files not supplied. HALT!"
	exit 1
fi

if [ -z "$4" ]; then
	echo "$scriptName : Absolute Path of Configuration Files not supplied. HALT!"
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
