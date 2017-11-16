#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 Properties file not supplied"
	exit 1
else
	PROP_FILE=$1
fi

if [ -z "$2" ]; then
	echo "$0 Property name not supplied"
	exit 1
else
	PROP_NAME=$2
fi

# No diagnostics or information can be echoed in this script as the echo is used as the return mechanism
sed -e 's/#.*$//' -e '/^ *$/d' $PROP_FILE > fileWithoutComments

while read LINE
do           
	IFS="\="
	read -ra array <<< "$LINE"
	if [ "${array[0]}" == "$PROP_NAME" ]; then
		echo "${array[1]}"
	fi
done < fileWithoutComments

rm fileWithoutComments
