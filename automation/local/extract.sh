#!/usr/bin/env bash
set -e

echo
echo "$0 : Extract $1 to $2"
unzip $2/$1.zip -d $2/$1
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Extract $1 to $2 failed! Returned $exitCode"
	exit $exitCode
fi
