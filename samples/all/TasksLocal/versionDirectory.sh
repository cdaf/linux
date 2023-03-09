#!/usr/bin/env bash
function executeExpression {
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='versionDirectory.sh'

echo; echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "[$scriptName] Directory not supplied, pass as absolute path i.e. /etc/init.d/bonita. HALT!"
	exit 1
else
	ABS_PATH=$1
fi
echo "[$scriptName] ABS_PATH       : $ABS_PATH"

if [ -z "$2" ]; then
	echo "[$scriptName] Version not supplied. HALT!"
	exit 1
else
	BUILDNUMBER=$2
fi
echo "[$scriptName] BUILDNUMBER    : $BUILDNUMBER"

if [ -z "$3" ]; then
	MASK="*"
	echo "[$scriptName] MASK           : $MASK (default)"
else
	MASK=$3
	echo "[$scriptName] MASK           : $MASK"
fi

if [ -z "$4" ]; then
	echo "[$scriptName] MARKER         : (not supplied, versionReplace will use default)"
else
	MARKER=$4
	echo "[$scriptName] MARKER         : $MARKER"
fi

if [ -z $AUTOMATIONROT ]; then
	AUTOMATIONROOT="$( cd "$(dirname "$0")" && pwd )"
fi
echo "[$scriptName] AUTOMATIONROOT = $AUTOMATIONROOT"

# Create target directories if missing
for dirName in $(find .$ABS_PATH -type d); do
	if [ ! -d "${dirName:1}" ]; then
		mkdir -pv ${dirName:1}
	fi
done

echo; echo "[$scriptName] Processing directory $1 (only differences will be reported ...)"
for file in $(find .$ABS_PATH -name "$MASK" -type f); do
	executeExpression "  $AUTOMATIONROOT/versionReplace.sh '${file:1}' $BUILDNUMBER $MARKER"
done

echo; echo "[$scriptName] --- stop ---";echo
