#!/usr/bin/env bash
set -e
scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "$scriptName : Version not passed. HALT!"
	exit 1
else
	VERSION=$1
fi

if [ -z "$2" ]; then
	echo "$scriptName : Environment not passed. HALT!"
	exit 2
else
	ENVIRONMENT=$2
fi

if [ -z "$3" ]; then
	echo "$scriptName : Environment not passed. HALT!"
	exit 3
else
	TARGET=$3
fi

echo
echo "$scriptName : +-------------+"
echo "$scriptName : | Diagnostics |"
echo "$scriptName : +-------------+"
echo
echo "$scriptName :   VERSION     : $VERSION"
echo "$scriptName :   ENVIRONMENT : $ENVIRONMENT"
echo "$scriptName :   hostname    : $(hostname)"

echo
echo "$scriptName : Contents of version file :"
echo
cat ./manifest.txt
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Unable to list Contents of version file! Returned $exitCode"
	exit $exitCode
fi

echo
echo echo "$scriptName : Directory listing of working directory ($(pwd))"
ls -l
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Unable to list working directory $(pwd)! Returned $exitCode"
	exit $exitCode
fi

echo
echo echo "$scriptName : Directory listing parent directory"
ls -l ./
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Unable to list parent directory! Returned $exitCode"
	exit $exitCode
fi