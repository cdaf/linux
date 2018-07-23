#!/usr/bin/env bash

function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='build.sh'
echo; echo "[$scriptName] --- start ---"
PROJECT=$1
if [ -z "$PROJECT" ]; then
	echo "[$scriptName] PROJECT not passed!"; exit 1
else
	echo "[$scriptName]   PROJECT     : $PROJECT"
fi

BUILDNUMBER=$2
if [ -z "$BUILDNUMBER" ]; then
	echo "[$scriptName] BUILDNUMBER not passed!"; exit 2
else
	echo "[$scriptName]   BUILDNUMBER : $BUILDNUMBER"
fi

REVISION=$3
if [ -z "$REVISION" ]; then
	echo "[$scriptName] REVISION not passed!"; exit 3
else
	echo "[$scriptName]   REVISION    : $REVISION"
fi

BUILDENV=$4
if [ -z "$BUILDENV" ]; then
	echo "[$scriptName]   BUILDENV    : (not supplied)"
else
	echo "[$scriptName]   BUILDENV    : $BUILDENV"
fi

ACTION=$5
if [ -z "$ACTION" ]; then
	echo "[$scriptName]   ACTION      : (not supplied)"
else
	echo "[$scriptName]   ACTION      : $ACTION"
fi

echo; echo "[$scriptName] Beware, CentOS has a packer binary that takes precedenced in non-interactive sessions"
executeExpression "which packer"

echo; echo "[$scriptName] verify packer install"
executeExpression "/usr/bin/packer --version"

echo; echo "[$scriptName] verify packer install"
executeExpression "/usr/bin/packer build ubuntu.json"

echo; echo "[$scriptName] --- end ---"; echo
