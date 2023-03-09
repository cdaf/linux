#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Failed with exit: $exitCode"; echo; exit $exitCode
	fi
}  

scriptName=${0##*/}

echo
echo "[$scriptName] --- start ---"
virtualenv=$1
if [ -z "$virtualenv" ]; then
	echo "$scriptName virtualenv not supplied, exit with error code 1"; exit 1
else
	echo "$scriptName virtualenv : $virtualenv"
fi

playbook=$2
if [ -z "$playbook" ]; then
	echo "$scriptName playbook not supplied, exit with error code 2"; exit 2
else
	echo "$scriptName playbook   : $playbook"
fi

inventory=$3
if [ -z "$inventory" ]; then
	echo "$scriptName inventory not supplied, exit with error code 3"; exit 3
else
	echo "$scriptName inventory  : $inventory"
fi

optArg=$4
if [ -z "$optArg" ]; then
	echo "$scriptName optArg not supplied"
else
	echo "$scriptName optArg    : $optArg"
fi

echo
echo "Switch to the Virtual Environment"
currentWorkspace=$(pwd)
executeExpression "source `which virtualenvwrapper.sh`"
executeExpression "cd ${virtualenv}"
executeExpression "workon $(workon)"
executeExpression "cd $currentWorkspace"

echo
executeExpression "ansible-playbook --version"

echo
executeExpression "ansible-playbook ${playbook} -i inventory/${inventory} ${optArg}"

echo
echo "[$scriptName] --- end ---"
