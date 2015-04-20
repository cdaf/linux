#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Solution not supplied. HALT!"
	exit 1
else
	SOLUTION=$1
fi

if [ -z "$2" ]; then
	echo "$0 : Target not supplied. HALT!"
	exit 2
else
	TARGET=$2
fi

containerPath=$(./getProperty.sh "../$TARGET" "containerPath")
if [ -z "$containerPath" ]; then
	echo "$0 : Unable to retrieve containerPath value from ../$TARGET! Returning exit 99"
	exit 99
fi

context=$(./getProperty.sh "../$TARGET" "context")
if [ -z "$context" ]; then
	echo "$0 : Unable to retrieve context value from ../$TARGET! Returning exit 98"
	exit 98
fi

appSource=$(./getProperty.sh "../$TARGET" "appSource")
if [ -z "$appSource" ]; then
	echo "$0 : Unable to retrieve appSource value from ../$TARGET! Returning exit 98"
	exit 98
fi

# Deploy the WAR file, with environment as suffix
echo
printf "$0 : "
cp -v ../$appSource $containerPath/$context
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : cp -v ../$appSource $containerPath/$context failed! Returned $exitCode"
	exit $exitCode
fi
