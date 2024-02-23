#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# Deploy script for running on the local host, all solution parameters are read from the manifest
# deployment properties, i.e. the unique values for this deployment are read from target properties file. 
if [ -z "$1" ]; then
	echo "[$scriptName] Deployment Target name not passed. HALT!"
	exit 1
else
	TARGET=$1
	if [[ $TARGET == *'$'* ]]; then
		TARGET=$(eval echo $TARGET)
	fi
	echo
	echo "[$scriptName]   TARGET               : $TARGET"
fi

# If passed, change to the working directory, if not passed, execute in current directory
if [ -z "$2" ]; then
	WORK_DIR_DEFAULT=$(pwd)
	echo "[$scriptName]   WORK_DIR_DEFAULT     : $WORK_DIR_DEFAULT (not set, using current working directory)"
else
	cd "$2"
	WORK_DIR_DEFAULT=$(pwd)
	echo "[$scriptName]   WORK_DIR_DEFAULT     : $2 ($WORK_DIR_DEFAULT)"
fi
export CDAF_CORE="${WORK_DIR_DEFAULT}"

if [ -z "$3" ]; then
	echo "[$scriptName]   RELEASE              : (not supplied)"
else
	RELEASE=$3
	if [[ $RELEASE == *'$'* ]]; then
		RELEASE=$(eval echo $RELEASE)
	fi
	export RELEASE=$RELEASE
	echo "[$scriptName]   RELEASE              : $RELEASE"
fi

if [ -z "$4" ]; then
	echo "[$scriptName]   OPT_ARG              : (not supplied)"
else
	OPT_ARG=$4
	if [[ $OPT_ARG == *'$'* ]]; then
		OPT_ARG=$(eval echo $OPT_ARG)
	fi
	export OPT_ARG=$OPT_ARG
	echo "[$scriptName]   OPT_ARG              : $OPT_ARG"
fi

# Load solution and build number from Manifest (created in package process)
SOLUTION=$("${CDAF_CORE}/getProperty.sh" "./manifest.txt" "SOLUTION")
echo "[$scriptName]   SOLUTION             : $SOLUTION"
BUILDNUMBER=$("${CDAF_CORE}/getProperty.sh" "./manifest.txt" "BUILDNUMBER")
echo "[$scriptName]   BUILDNUMBER          : $BUILDNUMBER"

echo "[$scriptName]   whoami               : $(whoami)"
echo "[$scriptName]   hostname             : $(hostname)"

cdafVersion=$("${CDAF_CORE}/getProperty.sh" "${CDAF_CORE}/CDAF.properties" "productVersion")
echo "[$scriptName]   CDAF Version         : $cdafVersion"

scriptOverride=$("${CDAF_CORE}/getProperty.sh" "./$TARGET" "deployScriptOverride")
if [ "$scriptOverride" ]; then
	if [ ! -f "./$scriptOverride" ]; then
		echo "[$scriptName] $scriptOverride not found!"
		exit 127
	fi
	echo "[$scriptName]   deployScriptOverride : deployScriptOverride"  
	printf "[$scriptName]   Executing ==> "  
	overrideExecute="./$scriptOverride '$SOLUTION' '$BUILDNUMBER' '$TARGET' '$OPT_ARG'"
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
	taskOverride=$("${CDAF_CORE}/getProperty.sh" "./$TARGET" "deployTaskOverride")
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
		"${CDAF_CORE}/execute.sh" "$SOLUTION" "$BUILDNUMBER" "$TARGET" "$overrideTask" "$OPT_ARG"
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] ${CDAF_CORE}/execute.sh $SOLUTION $BUILDNUMBER $TARGET $overrideTask $OPT_ARG failed! Returned $exitCode"
			exit $exitCode
		fi
	done
fi
