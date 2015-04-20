#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Environment not passed. HALT!"
	exit 1
else
	TARGET=$1
fi

echo
echo "$0 : Get Property value (containerPath) from ../$TARGET using getProperty.sh"
echo 
./getProperty.sh "../$TARGET" "containerPath"
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Retrieval of containerPath from $TARGET failed! Returned $exitCode"
	exit $exitCode
fi
