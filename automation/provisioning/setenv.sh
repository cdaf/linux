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

scriptName='setenv.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "variable not passed, HALT!"
	exit 1
else
	variable="$1"
	# The variable name will be used as the script name
	echo "[$scriptName]   variable : $variable"
fi

if [ -z "$2" ]; then
	echo "Value not passed, HALT!"
	exit 1
else
	value="$2"
	echo "[$scriptName]   value    : $value"
fi

level="$3"
if [ -z "$level" ]; then
	level='machine'
	echo "[$scriptName]   level    : $level (default)"
else
	if [ "$level" == 'machine' ] || [ "$level" == 'user' ]; then
		echo "[$scriptName]   level    : $level"
	else
		echo "[$scriptName] level must be machine or user, exiting with code 3"; exit 3
	fi
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami  : $(whoami)"
else
	echo "[$scriptName]   whoami  : $(whoami) (elevation not required)"
fi

if [ "$level" == 'user' ]; then
	executeExpression "echo 'export $variable=\"$value\"' >> $HOME/.bashrc"
	executeExpression "source $HOME/.bashrc"
else
	systemLocation='/etc/profile.d/'
	startScript="$variable"
	startScript+='.sh'
	executeExpression "echo 'export $variable=\"$value\"' > $startScript"
	executeExpression "chmod +x $startScript"
	executeExpression "$elevate cp -rv $startScript $systemLocation"
	executeExpression "rm $startScript"
	executeExpression "source $systemLocation/$startScript"
fi

executeExpression "echo \$$variable"

echo "[$scriptName] --- end ---"
