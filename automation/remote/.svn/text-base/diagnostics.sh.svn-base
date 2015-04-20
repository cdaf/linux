#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Version not passed. HALT!"
	exit 1
else
	VERSION=$1
fi

if [ -z "$2" ]; then
	echo "$0 : Environment not passed. HALT!"
	exit 2
else
	ENVIRONMENT=$2
fi

if [ -z "$3" ]; then
	echo "$0 : Environment not passed. HALT!"
	exit 3
else
	TARGET=$3
fi

echo
echo "$0 : +-------------+"
echo "$0 : | Diagnostics |"
echo "$0 : +-------------+"
echo
echo "$0 :   VERSION     : $VERSION"
echo "$0 :   ENVIRONMENT : $ENVIRONMENT"
echo "$0 :   hostname    : $(hostname)"

echo
echo "$0 : Contents of version file :"
echo
cat ../manifest.txt
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Unable to list Contents of version file! Returned $exitCode"
	exit $exitCode
fi

echo
echo echo "$0 : Directory listing of working directory ($(pwd))"
ls -l
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Unable to list working directory $(pwd)! Returned $exitCode"
	exit $exitCode
fi

echo
echo echo "$0 : Directory listing parent directory"
ls -l ../
if [ "$exitCode" != "0" ]; then
	echo "$0 : Unable to list parent directory! Returned $exitCode"
	exit $exitCode
fi