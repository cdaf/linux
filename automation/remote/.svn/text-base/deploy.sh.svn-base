#!/usr/bin/env bash
set -e

# Deploy script for running on the local host, all solution parameters are read from the manifest
# deployment properties, i.e. the unique values for this deployment are read from target properties file. 
if [ -z "$1" ]; then
	echo "$0 : Deployment Target name not passed. HALT!"
	exit 1
else
	DEPLOY_TARGET=$1
fi

# Optional, i.e. normally only supplied by automated trigger
WORKING=$2

echo
echo "$0 : ---- Entering deploy process ----"
echo "$0 :   DEPLOY_TARGET : $DEPLOY_TARGET"
echo "$0 :   WORKING       : $WORKING"
echo

# If passed, change to the working directory, if not passed, execute in current directory

if [ ! -z "$WORKING" ]; then
	cd $WORKING
fi

echo "$0 : Load solution properties from manifest.txt"
echo
manifestProperties=$(./transform.sh "../manifest.txt")
echo "$manifestProperties"
eval $manifestProperties

echo
echo "$0 : Running as $(whoami) in $(pwd) on $(hostname) using properties $DEPLOY_TARGET"
echo "$0 : Logging to $(pwd)/deploy.log"

scriptList=$(./getProperty.sh "../$DEPLOY_TARGET" "deployScriptOverride")
if [ -z "$scriptList" ]; then
	scriptList="tasksRunRemote.tsk"
fi

echo
echo "$0 : Starting deploy process ..."
./execute.sh "$SOLUTION" "$BUILDNUMBER" "$DEPLOY_TARGET" "$scriptList" 2>&1 | tee -a deploy.log
# the pipe above will consume the exit status, so use array of status of each command in your last foreground pipeline of commands
exitCode=${PIPESTATUS[0]} 
if [ "$exitCode" != "0" ]; then
	echo "$0 : Main Deployment activity failed! Returned $exitCode"
	exit $exitCode
fi

echo
echo "$0 : Deployment Complete."
echo

