#!/usr/bin/env bash
set -e
scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "$scriptName Properties file not supplied"
	exit 1870
else
	PROP_FILE="$1"
	if [ ! -f "$PROP_FILE" ]; then
		>&2 echo "Property File $PROP_FILE not found!"
		exit 1872
	fi
fi

if [ -z "$2" ]; then
	echo "$scriptName Property name not supplied"
	exit 1871
else
	PROP_NAME="$2"
fi

# No diagnostics or information can be echoed in this script as the echo is used as the return mechanism
fileWithoutComments=$(sed -e 's/#.*$//' -e '/^ *$/d' "$PROP_FILE")
while read -r LINE; do
	IFS="\="
	read -ra array <<< "$LINE"
	if [ "${array[0]}" == "$PROP_NAME" ]; then
		echo "${array[1]}"
	fi
done < <(echo "$fileWithoutComments")
