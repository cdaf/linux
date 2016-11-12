#!/bin/bash
# Entry point for Delivery automation.

scriptName=${0##*/}

echo
echo "$scriptName : ================================="
echo "$scriptName : Continuous Delivery (CD) Starting"
echo "$scriptName : ================================="

ENVIRONMENT="$1"
if [[ $ENVIRONMENT == *'$'* ]]; then
	ENVIRONMENT=$(eval echo $ENVIRONMENT)
fi
if [ -z $ENVIRONMENT ]; then
	echo "$scriptName : Environment required! EXiting code 1"; exit 1
fi 
echo "$scriptName :   ENVIRONMENT      : $ENVIRONMENT"

RELEASE="$2"
if [[ $RELEASE == *'$'* ]]; then
	RELEASE=$(eval echo $RELEASE)
fi
if [ -z $RELEASE ]; then
	RELEASE='Release'
	echo "$scriptName :   RELEASE          : $RELEASE (default)"
else
	echo "$scriptName :   RELEASE          : $RELEASE"
fi 

OPT_ARG="$3"
echo "$scriptName :   OPT_ARG          : $OPT_ARG"

LOCAL_WORK_DIR="$4"
if [ -z $WORK_DIR_DEFAULT ]; then
	WORK_DIR_DEFAULT='TasksLocal'
fi 
echo "$scriptName :   WORK_DIR_DEFAULT : $WORK_DIR_DEFAULT"

SOLUTION="$5"
if [[ $SOLUTION == *'$'* ]]; then
	SOLUTION=$(eval echo $SOLUTION)
fi
if [ -z $SOLUTION ]; then
	SOLUTION=$(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/manifest.txt" "SOLUTION")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Read of SOLUTION from ./$WORK_DIR_DEFAULT/manifest.txt failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "$scriptName :   SOLUTION         : $SOLUTION (derived from $WORK_DIR_DEFAULT/manifest.txt)"
else
	echo "$scriptName :   SOLUTION         : $SOLUTION"
fi 

BUILDNUMBER="$6"
if [[ $BUILDNUMBER == *'$'* ]]; then
	BUILDNUMBER=$(eval echo $BUILDNUMBER)
fi
if [ -z $BUILDNUMBER ]; then
	BUILDNUMBER=$(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/manifest.txt" "BUILDNUMBER")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Read of BUILDNUMBER from ./$WORK_DIR_DEFAULT/manifest.txt failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "$scriptName :   BUILDNUMBER      : $BUILDNUMBER (derived from $WORK_DIR_DEFAULT/manifest.txt)"
else
	echo "$scriptName :   BUILDNUMBER      : $BUILDNUMBER"
fi 

echo "$scriptName :   whoami           : $(whoami)"
echo "$scriptName :   hostname         : $(hostname)"
echo "$scriptName :   CDAF Version     : $(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/CDAF.properties" "productVersion")"
workingDir=$(pwd)
echo "$scriptName :   workingDir       : $workingDir"

./$WORK_DIR_DEFAULT/remoteTasks.sh "$ENVIRONMENT" "$BUILDNUMBER" "$SOLUTION" "$WORK_DIR_DEFAULT" "$OPT_ARG"
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Remote Deploy process failed! Returned $exitCode"
	echo "$scriptName : ./$WORK_DIR_DEFAULT/remoteTasks.sh $ENVIRONMENT $BUILDNUMBER $SOLUTION $WORK_DIR_DEFAULT $OPT_ARG"
	exit $exitCode
fi

./$WORK_DIR_DEFAULT/localTasks.sh "$ENVIRONMENT" "$BUILDNUMBER" "$SOLUTION" "$WORK_DIR_DEFAULT" "$OPT_ARG"
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Remote Deploy process failed! Returned $exitCode"
	echo "$scriptName : ./$WORK_DIR_DEFAULT/localTasks.sh $ENVIRONMENT $BUILDNUMBER $SOLUTION $WORK_DIR_DEFAULT $OPT_ARG"
	exit $exitCode
fi
