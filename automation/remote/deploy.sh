#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# Deploy script for running on the local host, all solution parameters are read from the manifest
# deployment properties, i.e. the unique values for this deployment are read from target properties file. 
if [ -z "$1" ]; then
	echo "[$scriptName] Deployment Target name not passed. HALT!"
	exit 1
else
	DEPLOY_TARGET=$1
fi

# Optional, i.e. normally only supplied by automated trigger
WORK_DIR_DEFAULT=$2

echo
echo "[$scriptName]   DEPLOY_TARGET        : $DEPLOY_TARGET"
# If passed, change to the working directory, if not passed, execute in current directory
if [ "$WORK_DIR_DEFAULT" ]; then
	echo "[$scriptName]   WORK_DIR_DEFAULT     : $WORK_DIR_DEFAULT"
	cd $WORK_DIR_DEFAULT
	WORK_DIR_DEFAULT=$(pwd)
else
	WORK_DIR_DEFAULT=$(pwd)
	echo "[$scriptName]   WORK_DIR_DEFAULT     : $WORK_DIR_DEFAULT (not passed, using current)"
fi
export CDAF_CORE="${WORK_DIR_DEFAULT}"

# Load solution and build number from Manifest (created in package process)
SOLUTION=$("${CDAF_CORE}/getProperty.sh" "./manifest.txt" "SOLUTION")
echo "[$scriptName]   SOLUTION             : $SOLUTION"
BUILDNUMBER=$("${CDAF_CORE}/getProperty.sh" "./manifest.txt" "BUILDNUMBER")
echo "[$scriptName]   BUILDNUMBER          : $BUILDNUMBER"

# Optional, generic argument
if [ ! -z "$3" ]; then
	OPT_ARG=$3
fi
echo "[$scriptName]   OPT_ARG              : $OPT_ARG"

echo "[$scriptName]   whoami               : $(whoami)"
echo "[$scriptName]   hostname             : $(hostname)"

cdafVersion=$("${CDAF_CORE}/getProperty.sh" "${CDAF_CORE}/CDAF.properties" "productVersion")
echo "[$scriptName]   CDAF Version         : $cdafVersion"

scriptOverride=$("${CDAF_CORE}/getProperty.sh" "./$DEPLOY_TARGET" "deployScriptOverride")
if [ "$scriptOverride" ]; then
	if [ ! -f "./$scriptOverride" ]; then
		echo "[$scriptName] $scriptOverride not found!"
		exit 127
	fi
	echo "[$scriptName]   deployScriptOverride : deployScriptOverride"  
	printf "[$scriptName]   Executing ==> "  
	overrideExecute="./$scriptOverride '$SOLUTION' '$BUILDNUMBER' '$DEPLOY_TARGET' '$OPT_ARG'"
	echo
	echo "$overrideExecute"
	eval $overrideExecute
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] $scriptOverride failed! Returned $exitCode"
		exit $exitCode
	fi
		
else

	echo "[$scriptName]   deployScriptOverride : (not set)"  
	taskOverride=$("${CDAF_CORE}/getProperty.sh" "./$DEPLOY_TARGET" "deployTaskOverride")
	if [ "$taskOverride" ]; then
		echo "[$scriptName]   deployTaskOverride   : $taskOverride"
	else
		taskOverride="tasksRunRemote.tsk"
		echo "[$scriptName]   deployTaskOverride   : tasksRunRemote.tsk (default)"
	fi
	for overrideTask in $taskOverride; do
		if [ ! -f $overrideTask ]; then
			echo "[$scriptName][ERROR] $overrideTask not found! List workspace contents and exit with code 3226"
			ls -al
			exit 3226
		fi
		echo
		echo "[$scriptName] Starting deploy process ..."
		"${CDAF_CORE}/execute.sh" "$SOLUTION" "$BUILDNUMBER" "$DEPLOY_TARGET" "$overrideTask" "$OPT_ARG"
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] ${CDAF_CORE}/execute.sh $SOLUTION $BUILDNUMBER $DEPLOY_TARGET $overrideTask $OPT_ARG failed! Returned $exitCode"
			exit $exitCode
		fi
	done
fi
