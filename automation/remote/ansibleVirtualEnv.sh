#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Failed with exit: $exitCode"; echo; exit $exitCode
	fi
}  

scriptName='ansibleVirtualEnv.sh'

echo
echo "[$scriptName] --- start ---"
virtualenv=$1
if [ -z "$virtualenv" ]; then
	echo "$0 virtualenv not supplied, exit with error code 1"; exit 1
else
	echo "$0 virtualenv : $virtualenv"
fi

playbook=$2
if [ -z "$playbook" ]; then
	echo "$0 playbook not supplied, exit with error code 2"; exit 2
else
	echo "$0 playbook   : $playbook"
fi

inventory=$3
if [ -z "$inventory" ]; then
	echo "$0 inventory not supplied, exit with error code 3"; exit 3
else
	echo "$0 inventory  : $inventory"
fi

optArg=$4
if [ -z "$optArg" ]; then
	echo "$0 optArg not supplied"
else
	echo "$0 optArg    : $optArg"
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
