#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# Deploy script for running on the local host, all solution parameters are read from the manifest
# deployment properties, i.e. the unique values for this deployment are read from target properties file. 
if [ -z "$1" ]; then
	echo "$scriptName : Deployment Target name not passed. HALT!"
	exit 1
else
	DEPLOY_TARGET=$1
fi

# Optional, i.e. normally only supplied by automated trigger
WORKDIR=$2

# Optional, generic argument
OPT_ARG=$3

echo
echo "$scriptName :   DEPLOY_TARGET        : $DEPLOY_TARGET"
# If passed, change to the working directory, if not passed, execute in current directory
if [ "$WORKDIR" ]; then
	cd $WORKDIR
	echo "$scriptName :   WORKDIR              : $WORKDIR"
else
	echo "$scriptName :   WORKDIR              : $(pwd) (not passed, using current)"
fi

# Load solution and build number from Manifest (created in package process)
SOLUTION=$(./$LOCAL_DIR_DEFAULT/getProperty.sh "./manifest.txt" "SOLUTION")
echo "$scriptName :   SOLUTION             : $SOLUTION"
BUILDNUMBER=$(./$LOCAL_DIR_DEFAULT/getProperty.sh "./manifest.txt" "BUILDNUMBER")
echo "$scriptName :   BUILDNUMBER          : $BUILDNUMBER"

if [ "$OPT_ARG" ]; then
	echo "$scriptName :   OPT_ARG              : $OPT_ARG"
else
	echo "$scriptName :   OPT_ARG              : (not passed)"
fi

echo "$scriptName :   whoami               : $(whoami)"
echo "$scriptName :   hostname             : $(hostname)"

cdafVersion=$(./$LOCAL_DIR_DEFAULT/getProperty.sh "./$LOCAL_DIR_DEFAULT/CDAF.properties" "productVersion")
echo "$scriptName :   CDAF Version         : $cdafVersion"

scriptOverride=$(./getProperty.sh "./$DEPLOY_TARGET" "deployScriptOverride")
if [ "$scriptOverride" ]; then
	if [ ! -f "./$scriptOverride" ]; then
		echo "$scriptName : $scriptOverride not found!"
		exit 127
	fi	 	
	echo "$scriptName :   deployScriptOverride : deployScriptOverride"  
	printf "$scriptName :   Executing ==> "  
	overrideExecute="./$scriptOverride $SOLUTION $BUILDNUMBER $DEPLOY_TARGET"
	echo
	echo "$overrideExecute"
	eval $overrideExecute
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$scriptName : $scriptOverride failed! Returned $exitCode"
		exit $exitCode
	fi
		
else

	echo "$scriptName :   deployScriptOverride : (not set)"  
	taskOverride=$(./getProperty.sh "./$DEPLOY_TARGET" "deployTaskOverride")
	if [ "$taskOverride" ]; then
		echo "$scriptName :   deployTaskOverride   : $taskOverride"
	else
		taskOverride="tasksRunRemote.tsk"
		echo "$scriptName :   deployTaskOverride   : tasksRunRemote.tsk (default)"
	fi
	for overrideTask in $taskOverride; do
		if [ ! -f $overrideTask ]; then
			echo "$scriptName $overrideTask not found! Exit with code 3226"
			exit 3226
		fi
		echo
		echo "$scriptName : Starting deploy process ..."
		./execute.sh "$SOLUTION" "$BUILDNUMBER" "$DEPLOY_TARGET" "$overrideTask" "$OPT_ARG"
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "$scriptName : ./execute.sh $SOLUTION $BUILDNUMBER $DEPLOY_TARGET $overrideTask $OPT_ARG failed! Returned $exitCode"
			exit $exitCode
		fi
	done
fi
