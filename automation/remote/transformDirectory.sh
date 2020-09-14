#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='transformDirectory.sh'

echo; echo "[$scriptName] --- start ---"
echo
if [ -z "$1" ]; then
	echo "[$scriptName] Properties file not supplied. HALT!"
	exit 1
else
	PROPERTIES=$1
fi

if [ -z "$2" ]; then
	echo "[$scriptName] Directory not supplied, defaulting to current"
	DIR_PATH="."
else
	DIR_PATH="$2"
fi

if [ -z "$3" ]; then
	echo "[$scriptName] Mask not supplied, defaulting to *"
	MASK="*"
else
	MASK="$3"
fi

if [ -z $AUTOMATIONROT ]; then
	AUTOMATIONROOT="$( cd "$(dirname "$0")" ; pwd -P )"
fi
echo "[$scriptName] AUTOMATIONROOT = $AUTOMATIONROOT"

echo "[$scriptName] Processing directory $DIR_PATH/$MASK"
for file in $(find $DIR_PATH -name "$MASK" -type f); do
	executeExpression "  $AUTOMATIONROOT/transform.sh '$PROPERTIES' '$file'"
done

echo; echo "[$scriptName] --- stop ---";echo
