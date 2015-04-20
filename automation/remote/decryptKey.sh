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

if [ -z "$3" ]; then
	echo "$0 : Encrypted file not supplied. HALT!"
	exit 3
else
	CRYPTFILE=$3
fi

privateKey=$(./getProperty.sh "../$TARGET" "privateKey")
if [ -z "$privateKey" ]; then
	echo "$0 : Unable to retrieve privateKey value from ../$TARGET! Returning exit 99"
	exit 99
fi

# This return value should be consumed by a variable and not logged 
password=$(openssl rsautl -decrypt -inkey $privateKey -in ../$CRYPTFILE) 
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Unable to deploy $context! Returned $exitCode"
	exit $exitCode
fi
echo $password