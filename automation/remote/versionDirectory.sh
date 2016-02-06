#!/usr/bin/env bash
#set -e

if [ -z "$1" ]; then
	echo "$0 : Directory not supplied, pass as absolute path i.e. /etc/init.d/bonita. HALT!"
	exit 1
else
	ABS_PATH=$1
fi

if [ -z "$2" ]; then
	echo "$0 : Version not supplied. HALT!"
	exit 1
else
	BUILDNUMBER=$2
fi

if [ -z "$3" ]; then
	echo "$0 : Mask not supplied, defaulting to *"
	MASK="*"
else
	MASK=$3
fi

# Create target directory if missing
if [ ! -d "$ABS_PATH" ]; then
	mkdir -pv $DIR_PATH
	echo
fi

echo "$0 : Processing directory $1 (only differences will be reported ...)"
ls -L -1 .$ABS_PATH/$MASK | xargs -n 1 basename > FILE_LIST

while read LINE
do
	./versionReplace.sh "$ABS_PATH/$LINE" "$BUILDNUMBER"           
done < FILE_LIST
