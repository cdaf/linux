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

# Optional, generic argument
OPT_ARG=$3

echo
echo "$0 :   DEPLOY_TARGET        : $DEPLOY_TARGET"
# If passed, change to the working directory, if not passed, execute in current directory
if [ "$WORKDIR" ]; then
	cd $WORKDIR
	echo "$0 :   WORKDIR              : $WORKDIR"
else
	echo "$0 :   WORKDIR              : $(pwd) (not passed, using current)"
fi

# Load solution and build number from Manifest (created in package process)
SOLUTION=$(./$LOCAL_DIR_DEFAULT/getProperty.sh "./manifest.txt" "SOLUTION")
echo "$0 :   SOLUTION             : $SOLUTION"
BUILDNUMBER=$(./$LOCAL_DIR_DEFAULT/getProperty.sh "./manifest.txt" "BUILDNUMBER")
echo "$0 :   BUILDNUMBER          : $BUILDNUMBER"

if [ "$OPT_ARG" ]; then
	echo "$0 :   OPT_ARG              : $OPT_ARG"
else
	echo "$0 :   OPT_ARG              : (not passed)"
fi

echo "$0 :   whoami               : $(whoami)"
echo "$0 :   hostname             : $(hostname)"

cdafVersion=$(./$LOCAL_DIR_DEFAULT/getProperty.sh "./$LOCAL_DIR_DEFAULT/CDAF.properties" "productVersion")
echo "$0 :   CDAF Version         : $cdafVersion"

scriptOverride=$(./getProperty.sh "./$DEPLOY_TARGET" "deployScriptOverride")
if [ "$scriptOverride" ]; then
	if [ ! -f "./$scriptOverride" ]; then
		echo "$0 : $scriptOverride not found!"
		exit 127
	fi	 	
	echo "$0 :   deployScriptOverride : deployScriptOverride"  
	printf "$0 :   Executing ==> "  
	overrideExecute="./$scriptOverride $SOLUTION $BUILDNUMBER $DEPLOY_TARGET"
	echo
	echo "$overrideExecute"
	eval $overrideExecute
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : $scriptOverride failed! Returned $exitCode"
		exit $exitCode
	fi
		
else

	echo "$0 :   deployScriptOverride : (not set)"  
	taskOverride=$(./getProperty.sh "./$DEPLOY_TARGET" "deployTaskOverride")
	if [ "$taskOverride" ]; then
		echo "$0 :   deployTaskOverride   : $taskOverride"
	else
		taskOverride="tasksRunRemote.tsk"
		echo "$0 :   deployTaskOverride   : tasksRunRemote.tsk (default)"
	fi
	echo
	echo "$0 : Starting deploy process ..."
	./execute.sh "$SOLUTION" "$BUILDNUMBER" "$DEPLOY_TARGET" "$taskOverride" "$OPT_ARG"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : ./execute.sh $SOLUTION $BUILDNUMBER $DEPLOY_TARGET $taskOverride $OPT_ARG failed! Returned $exitCode"
		exit $exitCode
	fi

fi
