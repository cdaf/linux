#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "$0 : Properties file not supplied. HALT!"
	exit 1
else
	PROPERTIES=$1
fi

if [ -z "$2" ]; then
	echo "$0 : Directory not supplied, defaulting to current"
	DIR_PATH="."
else
	DIR_PATH="$2"
fi

if [ -z "$3" ]; then
	echo "$0 : Mask not supplied, defaulting to *"
	MASK="*"
else
	MASK="$3"
fi

echo "$0 : Processing directory $DIR_PATH/$MASK"
ls -L -1 $DIR_PATH/$MASK | xargs -n 1 basename > FILE_LIST

runTime="./transform.sh"
if [ ! -f "$runTime" ]; then
	for i in $(ls -d ../*/); do
		directoryName=${i%%/}
		if [ -f "$directoryName/CDAF.automation" ]; then
			automationRoot="$directoryName"
		fi
	done
	runTime="$automationRoot/remote/transform.sh"
fi
echo "$0 : Set runtime to $runTime"

while read LINE
do
	$runTime "$PROPERTIES" "$DIR_PATH/$LINE"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$0 : ./transform.sh $PROPERTIES $DIR_PATH/$LINE  failed! Exit code = $exitCode."
		exit $exitCode
	fi
           
done < FILE_LIST
