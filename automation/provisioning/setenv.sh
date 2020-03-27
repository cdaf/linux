#!/usr/bin/env bash

function executeExpression {
	echo "$1"
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

secret="$4"
if [ -z "$secret" ]; then
	secret='no'
else
	if [ "$secret" != 'yes' ] && [ "$secret" != 'no' ]; then
		echo "[$scriptName] secret ($secret) must be yes or no, exiting with code 4"; exit 4
	fi
fi

if [ -z "$2" ]; then
	echo "Value not passed, HALT!"
	exit 1
else
	value="$2"
	if [[ "$secret" == 'yes' ]]; then
		echo "[$scriptName]   value    : **************"
	else
		echo "[$scriptName]   value    : $value"
	fi
fi

level="$3"
if [ -z "$level" ]; then
	level='machine'
	echo "[$scriptName]   level    : $level (default)"
else
	if [ "$level" == 'machine' ] || [ "$level" == 'user' ]; then
		echo "[$scriptName]   level    : $level"
	else
		echo "[$scriptName] level ($level) must be machine or user, exiting with code 3"; exit 3
	fi
fi

echo "[$scriptName]   secret   : $secret"

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami   : $(whoami)"
else
	echo "[$scriptName]   whoami   : $(whoami) (elevation not required)"
fi

if [ "$level" == 'user' ]; then
	if [[ "$secret" == 'no' ]]; then
		executeExpression "echo 'export $variable=\"$value\"' >> $HOME/.bashrc"
	else
		echo "export $variable=\"$value\"" >> $HOME/.bashrc
	fi
	executeExpression "source $HOME/.bashrc"
else
	systemLocation='/etc/profile.d/'
	startScript="$variable"
	startScript+='.sh'
	if [[ "$secret" == 'no' ]]; then
		executeExpression "echo 'export $variable=\"$value\"' > $startScript"
	else
		echo "export $variable=\"$value\"" > $startScript
	fi
	executeExpression "chmod +x $startScript"
	executeExpression "$elevate cp -rv $startScript $systemLocation"
	executeExpression "rm $startScript"
	executeExpression "source ${systemLocation}${startScript}"
fi

if [[ "$secret" == 'no' ]]; then
	executeExpression "echo \$$variable"
fi

echo "[$scriptName] --- end ---"
