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

scriptName='addPath.sh'

echo "[$scriptName] --- start ---"
absPath=$1
if [ -z "$absPath" ]; then
	echo "[$scriptName]   absolute path to be added not supplied!"; exit 110
else
	echo "[$scriptName]   absPath  : $absPath"
fi

pathID=$2
if [ -z "$pathID" ]; then
	pathID=$(echo "${absPath##*/}")
	echo "[$scriptName]   pathID   : $pathID (not supplied, defaulted to directory name)"
else
	echo "[$scriptName]   pathID   : $pathID"
fi

if [ "$(whoami)" != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami   : $(whoami)"
else
	echo "[$scriptName]   whoami   : $(whoami) (elevation not required)"
fi

echo "export PATH=${absPath}:\$PATH" > ${pathID}.sh

executeExpression "$elevate mv ${pathID}.sh /etc/profile.d/"
executeExpression "$elevate chmod +x /etc/profile.d/${pathID}.sh"
	
echo "[$scriptName] --- end ---"
