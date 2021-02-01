#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# This script provides a repeatable deployment process. This uses two arguments, the target environment
# identifier and the $3 to deploy. Note: each $3 produced is expected to be uniquely identifiable.
echo
echo "[$scriptName] +---------------------------------+"
echo "[$scriptName] | Process Remotely Executed Tasks |"
echo "[$scriptName] +---------------------------------+"
ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
	echo "$scriptName ENVIRONMENT Argument not passed. HALT!"
	exit 1331
else
	ENVIRONMENT=$1
	echo "[$scriptName]   ENVIRONMENT      : $ENVIRONMENT"
fi

RELEASE=$2
if [ -z "$RELEASE" ]; then
	echo "$scriptName RELEASE Argument not passed. HALT!"
	exit 1332
else
	echo "[$scriptName]   RELEASE          : $RELEASE"
fi

BUILDNUMBER=$3
if [ -z "$BUILDNUMBER" ]; then
	echo "$scriptName Build Number not passed. HALT!"
	exit 1333
else
	echo "[$scriptName]   BUILDNUMBER      : $BUILDNUMBER"
fi

SOLUTION=$4
if [ -z "$3" ]; then
	echo "[$scriptName] Solution Name not supplied. HALT!"
	exit 1334
else
	echo "[$scriptName]   SOLUTION         : $SOLUTION"
fi

landingDir=$(pwd)
WORK_DIR_DEFAULT=$5
if [ "$WORK_DIR_DEFAULT" ]; then
	echo "[$scriptName]   WORK_DIR_DEFAULT : $WORK_DIR_DEFAULT"
else
	WORK_DIR_DEFAULT=$landingDir
	echo "[$scriptName]   WORK_DIR_DEFAULT : $WORK_DIR_DEFAULT (not passed, using landing directory)"
fi

OPT_ARG=$6
if [ -z "$OPT_ARG" ]; then
	echo "[$scriptName]   OPT_ARG          : (Optional task argument not supplied)"
else
	echo "[$scriptName]   OPT_ARG          : $OPT_ARG"
fi

echo "[$scriptName]   whoami           : $(whoami)"
echo "[$scriptName]   hostname         : $(hostname)"
echo "[$scriptName]   pwd              : $(pwd)"

if [ -d "./$WORK_DIR_DEFAULT/propertiesForRemoteTasks" ]; then

	taskList=$(find ./$WORK_DIR_DEFAULT/propertiesForRemoteTasks -name "$ENVIRONMENT*" | sort)
	if [ ! -z "$taskList" ]; then
		echo; echo "[$scriptName] Preparing to process targets : "; echo		 
		for DEPLOY_TARGET in $taskList; do
			echo "  ${DEPLOY_TARGET##*/}"
		done
		echo

		for DEPLOY_TARGET in $taskList; do
			DEPLOY_TARGET=${DEPLOY_TARGET##*/}		
			./$WORK_DIR_DEFAULT/remoteDeployTarget.sh "$ENVIRONMENT" "$BUILDNUMBER" "$SOLUTION" "$DEPLOY_TARGET" "$WORK_DIR_DEFAULT" "$OPT_ARG"
			exitCode=$?
			if [ "$exitCode" != "0" ]; then
				echo "[$scriptName] ./$WORK_DIR_DEFAULT/remoteDeployTarget.sh $ENVIRONMENT $RELEASE $BUILDNUMBER $SOLUTION $DEPLOY_TARGET $WORK_DIR_DEFAULT $OPT_ARG failed! Returned $exitCode"
				exit $exitCode
			fi
		
			lastTarget=$(echo $DEPLOY_TARGET)
		
		done				
	else
		echo; echo "[$scriptName]   Properties directory (./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/) exists but contains no files, no action taken. Check that properties file exists with prefix of $ENVIRONMENT."
	fi
	
else
	echo; echo "[$scriptName]   Properties directory (./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/) not found, no action taken."
fi
