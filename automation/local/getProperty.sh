#!/usr/bin/env bash
set -e
scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "$scriptName Properties file not supplied"
	exit 1
else
	PROP_FILE=$1
fi

if [ -z "$2" ]; then
	echo "$scriptName Property name not supplied"
	exit 1
else
	PROP_NAME=$2
fi

# No diagnostics or information can be echoed in this script as the echo
# is used as the return mechanism
echo `cat $PROP_FILE | grep "$PROP_NAME" | cut -d'=' -f2`
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "[$scriptName] Retrieval of $PROP_NAME from $PROP_FILE failed! Returned $exitCode"
	exit $exitCode
fi
