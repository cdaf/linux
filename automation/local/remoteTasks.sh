#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# This script provides a repeatable deployment process. This uses two arguments, the target environment
# identifier and the $3 to deploy. Note: each $3 produced is expected to be uniquely identifiable.
echo
echo "$scriptName : +---------------------------------+"
echo "$scriptName : | Process Remotely Executed Tasks |"
echo "$scriptName : +---------------------------------+"

if [ -z "$1" ]; then
	echo "$scriptName Environment Argument not passed. HALT!"
	exit 1
else
	ENVIRONMENT=$1
	echo "$scriptName :   ENVIRONMENT       : $ENVIRONMENT"
fi

if [ -z "$2" ]; then
	echo "$scriptName Build Argument not passed. HALT!"
	exit 2
else
	BUILD=$2
	echo "$scriptName :   BUILD             : $BUILD"
fi

if [ -z "$3" ]; then
	echo "$scriptName : Solution Name not supplied. HALT!"
	exit 3
else
	SOLUTION=$3
	echo "$scriptName :   SOLUTION          : $SOLUTION"
fi

if [ -z "$4" ]; then
	echo "$scriptName : Default working directory not supplied. HALT!"
	exit 4
else
	LOCAL_DIR_DEFAULT=$4
	echo "$scriptName :   LOCAL_DIR_DEFAULT : $LOCAL_DIR_DEFAULT"
fi

if [ -z "$5" ]; then
	echo "$scriptName :   OPT_ARG           : (Optional task argument not supplied)"
else
	OPT_ARG=$5
	echo "$scriptName :   OPT_ARG           : $OPT_ARG"
fi
echo "$scriptName :   whoami            : $(whoami)"
echo "$scriptName :   hostname          : $(hostname)"
echo "$scriptName :   pwd               : $(pwd)"

if [ -d "./$LOCAL_DIR_DEFAULT/propertiesForRemoteTasks" ]; then

	taskList=$(find ./$LOCAL_DIR_DEFAULT/propertiesForRemoteTasks -name "$ENVIRONMENT*" | sort)
	if [ -n "$taskList" ]; then
		echo; echo "$scriptName : Preparing to process targets : "; echo		 
		for DEPLOY_TARGET in $taskList; do
			echo "  ${DEPLOY_TARGET##*/}"
		done
		echo

		for DEPLOY_TARGET in $taskList; do
			DEPLOY_TARGET=${DEPLOY_TARGET##*/}		
			./$LOCAL_DIR_DEFAULT/remoteDeployTarget.sh $ENVIRONMENT $BUILD $SOLUTION $DEPLOY_TARGET $LOCAL_DIR_DEFAULT $OPT_ARG
			exitCode=$?
			if [ "$exitCode" != "0" ]; then
				echo "$scriptName : ./$LOCAL_DIR_DEFAULT/remoteDeployTarget.sh $ENVIRONMENT $BUILD $SOLUTION $DEPLOY_TARGET $OPT_ARG failed! Returned $exitCode"
				exit $exitCode
			fi
		
			lastTarget=$(echo $DEPLOY_TARGET)
		
		done				
	else
		echo; echo "$scriptName :   Properties directory ($workingDir/$LOCAL_DIR_DEFAULT/propertiesForRemoteTasks/) exists but contains no files, no action taken. Check that properties file exists with prefix of $ENVIRONMENT."
	fi
	
else
	echo; echo "$scriptName :   Properties directory ($workingDir/$LOCAL_DIR_DEFAULT/propertiesForRemoteTasks/) not found, no action taken."
fi
