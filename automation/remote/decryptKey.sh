#!/usr/bin/env bash
# Cannot perform logging becuase the return value is anything echoed

set -e
scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "$scriptName : Target not supplied. HALT!"
	exit 1
else
	TARGET=$1
fi

if [ -z "$2" ]; then
	echo "$scriptName : Directory not supplied"
	exit 2
else
	DIRECTORY=$2
fi

if [ -z "$3" ]; then
	# Default to the same file name as the target, but in the supplied directory
	CRYPTFILE=$TARGET
else
	CRYPTFILE=$3
fi

# If a private key property is not found, use default
privateKey=$(./getProperty.sh "./$TARGET" "privateKey")
if [ -z "$privateKey" ]; then
	privateKey="$HOME/.ssl/private_key.pem"
fi

# This return value should be consumed by a variable and not logged 
password=$(openssl rsautl -decrypt -inkey $privateKey -in $DIRECTORY/$CRYPTFILE) 
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Unable to decrypt $CRYPTFILE! Returned $exitCode"
	exit $exitCode
fi
echo $password