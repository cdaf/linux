#!/usr/bin/env bash
set -e

# This script provides a repeatable deployment process. This uses two arguments, the target environment
# identifier and the $3 to deploy. Note: each $3 produced is expected to be uniquely identifiable.
echo
echo "$0 : +---------------------------------+"
echo "$0 : | Process Remotely Executed Tasks |"
echo "$0 : +---------------------------------+"

if [ -z "$1" ]; then
	echo "$0 Environment Argument not passed. HALT!"
	exit 1
else
	ENVIRONMENT=$1
	echo "$0 :   ENVIRONMENT       : $ENVIRONMENT"
fi

if [ -z "$2" ]; then
	echo "$0 Build Argument not passed. HALT!"
	exit 2
else
	BUILD=$2
	echo "$0 :   BUILD             : $BUILD"
fi

if [ -z "$3" ]; then
	echo "$0 : Solution Name not supplied. HALT!"
	exit 3
else
	SOLUTION=$3
	echo "$0 :   SOLUTION          : $SOLUTION"
fi

if [ -z "$4" ]; then
	echo "$0 : Default working directory not supplied. HALT!"
	exit 4
else
	LOCAL_DIR_DEFAULT=$4
	echo "$0 :   LOCAL_DIR_DEFAULT : $LOCAL_DIR_DEFAULT"
fi
echo "$0 :   whoami            : $(whoami)"
echo "$0 :   hostname          : $(hostname)"

cdafVersion=$(./$LOCAL_DIR_DEFAULT/getProperty.sh "./$LOCAL_DIR_DEFAULT/CDAF.properties" "productVersion")
echo "$0 :   CDAF Version      : $cdafVersion"

workingDir=$(pwd)
echo "$0 :   workingDir        : $workingDir"

if [ -d "./$LOCAL_DIR_DEFAULT/propertiesForRemoteTasks" ]; then
	
	ls -L -1 ./$LOCAL_DIR_DEFAULT/propertiesForRemoteTasks/$ENVIRONMENT* | xargs -n 1 basename > targetList &2> /dev/null
	
	# Pause 1 second for file processing to complete 
	sleep 1
	linecount=$(wc -l < "targetList")
	
	if (( $linecount > 0 )); then
		
		echo
		echo "$0 : Preparing to process targets : "
		echo		 
		while read LIST_TARGET
		do
			echo "  $LIST_TARGET"
		
		done < targetList
		echo
		while read DEPLOY_TARGET
		do
		
			./$LOCAL_DIR_DEFAULT/remoteDeployTarget.sh $ENVIRONMENT $BUILD $SOLUTION $DEPLOY_TARGET $LOCAL_DIR_DEFAULT
			exitCode=$?
			if [ "$exitCode" != "0" ]; then
				echo "$0 : ./$LOCAL_DIR_DEFAULT/remoteDeployTarget.sh $ENVIRONMENT $BUILD $SOLUTION $DEPLOY_TARGET failed! Returned $exitCode"
				exit $exitCode
			fi
		
			lastTarget=$(echo $DEPLOY_TARGET)
		
		done < targetList
		
		if [ -z $lastTarget ]; then
			echo
			echo "$0 : No Targets processed, if this is unexpected, check that properties file exists with prefix of $ENVIRONMENT."
			
		fi
		
		rm -f targetList
				
	else
		echo
		echo "$0 :   Properties directory ($workingDir/$LOCAL_DIR_DEFAULT/propertiesForRemoteTasks/) exists but contains no files, no action taken. Check that properties file exists with prefix of $ENVIRONMENT."
		
	fi
else
	echo
	echo "$0 :   Properties directory ($workingDir/$LOCAL_DIR_DEFAULT/propertiesForRemoteTasks/) not found, no action taken."
	
fi
