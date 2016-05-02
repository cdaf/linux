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
WORKDIR=$2

echo
echo "$0 :   DEPLOY_TARGET : $DEPLOY_TARGET"
# If passed, change to the working directory, if not passed, execute in current directory
if [ "$WORKDIR" ]; then
	cd $WORKDIR
	echo "$0 :   WORKDIR       : $WORKDIR"
else
	echo "$0 :   WORKDIR       : $(pwd) (not passed, using current)"
fi
echo "$0 :   whoami        : $(whoami)"
echo "$0 :   hostname      : $(hostname)"

cdafVersion=$(./$LOCAL_DIR_DEFAULT/getProperty.sh "./$LOCAL_DIR_DEFAULT/CDAF.properties" "productVersion")
echo "$0 :   CDAF Version  : $cdafVersion"
echo
echo "$0 : Load SOLUTION and BUILDNUMBER from manifest.txt"
echo
manifestProperties=$(./transform.sh "./manifest.txt")
echo "$manifestProperties"
eval $manifestProperties
echo
scriptOverride=$(./getProperty.sh "./$DEPLOY_TARGET" "deployScriptOverride")
if [ "$scriptOverride" ]; then
	echo
	if [ ! -f "./$scriptOverride" ]; then
		echo "$0 : $scriptOverride not found!"
		exit 127
	fi	 	
	printf "$0 : deployScriptOverride set, executing ==> "  
	overrideExecute="./$scriptOverride $SOLUTION $BUILDNUMBER $DEPLOY_TARGET"
	echo "$overrideExecute"
	eval $overrideExecute
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : $scriptOverride failed! Returned $exitCode"
		exit $exitCode
	fi
		
else

	taskOverride=$(./getProperty.sh "./$DEPLOY_TARGET" "deployTaskOverride")
	if [ -z "$taskOverride" ]; then
		taskOverride="tasksRunRemote.tsk"
		echo "$0 : deployTaskOverride not set, defaulting to tasksRunRemote.tsk"
	else
		echo "$0 : deployTaskOverride set to $deployTaskOverride, this will be executed"
	fi
	
	echo "$0 : Starting deploy process ..."
	./execute.sh "$SOLUTION" "$BUILDNUMBER" "$DEPLOY_TARGET" "$taskOverride" "$OPT_ARG"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Main Deployment activity failed! Returned $exitCode"
		exit $exitCode
	fi

fi
