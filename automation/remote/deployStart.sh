#!/usr/bin/env bash
set -e
scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "[$scriptName] Version not supplied. HALT!"
	exit 1
fi

if [ -z "$2" ]; then
	echo "[$scriptName] Environment Definition not supplied. HALT!"
	exit 1
fi

if [ -z "$3" ]; then
	echo "[$scriptName] List of Start Scripts not supplied. HALT!"
	exit 1
fi

if [ -z "$4" ]; then
	echo "[$scriptName] Absolute Path of Configuration Files not supplied. HALT!"
	exit 1
fi

# Path is received as absolute, when processing source, read realtive (..) 
# while target is the absolute path passed.

# Process Script List
while read SCRIPT
do
	# Apply the environment Startup scripts
	./transform.sh "./envDetoken/$2" "..$$4/$SCRIPT"
	./versionReplace.sh "$$4/$SCRIPT" $1

	EXEC_CHECK=$(ls -F -1 "$$4/$SCRIPT" | grep "*")
	if [ -z "$EXEC_CHECK" ]; then
		echo "[$scriptName] Set startup script $$4/$SCRIPT executable"
		chmod +x "$$4/$SCRIPT"
	fi
done < ./build/$3

