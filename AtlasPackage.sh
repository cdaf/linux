#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

function executeIgnore {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Warning! $EXECUTABLESCRIPT returned $exitCode"
	fi
}  

scriptName='AtlasPackage.sh'
echo; echo "[$scriptName] --- start ---"
boxName=$1
if [ -n "$boxName" ]; then
	echo "[$scriptName]   boxName : $boxName"
else
	echo "[$scriptName] boxName not passed, exit 1"; exit 1
fi

diskDir=$2
if [ -n "$diskDir" ]; then
	echo "[$scriptName]   diskDir : $diskDir"
else
	echo "[$scriptName] diskDir not passed, exit 2"; exit 2
fi

executeExpression "VBoxManage modifyhd '${$diskDir}/${boxName}/${boxName}.vdi' --compact"
executeExpression "vagrant package --base $boxName --output ${boxName}.box"
executeIgnore "vagrant box remove cdaf/$boxName --all" # ignore error if none exist
executeExpression "vagrant box add cdaf/$boxName ${boxName}.box --force"

echo; echo "[$scriptName] --- end ---"
exit 0
