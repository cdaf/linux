#!/bin/bash
# Emulate calling the package and deploy process as it would be from the automation toolset, 
# e.g. Bamboo or Jenkings, replacing BUILD with timestamp
# workspace with temp space. The variables provided in Jenkins are emulated in the scripts
# themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

SOLUTION="$1"
ENVIRONMENT="$2"
BUILD="$3"
RELEASE="$4"
LOCAL_WORK_DIR="$5"
REMOTE_WORK_DIR="$6"
OPT_ARG="$7"

scriptName=${0##*/}

echo
echo "$scriptName : ==========================================="
echo "$scriptName : Continuous Delivery (CD) Emulation Starting"
echo "$scriptName : ==========================================="
if [[ $SOLUTION == *'$'* ]]; then
	SOLUTION=$(eval echo $SOLUTION)
fi
echo "$scriptName :   SOLUTION        : $SOLUTION"
if [[ $ENVIRONMENT == *'$'* ]]; then
	ENVIRONMENT=$(eval echo $ENVIRONMENT)
fi
echo "$scriptName :   ENVIRONMENT     : $ENVIRONMENT"
if [[ $BUILD == *'$'* ]]; then
	BUILD=$(eval echo $BUILD)
fi
echo "$scriptName :   BUILD           : $BUILD"
if [[ $RELEASE == *'$'* ]]; then
	RELEASE=$(eval echo $RELEASE)
fi
echo "$scriptName :   RELEASE         : $RELEASE"
echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"
echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"
echo "$scriptName :   OPT_ARG         : $OPT_ARG"
echo "$scriptName :   whoami          : $(whoami)"
echo "$scriptName :   hostname        : $(hostname)"
echo "$scriptName :   CDAF Version    : $(./$LOCAL_WORK_DIR/getProperty.sh "./$LOCAL_WORK_DIR/CDAF.properties" "productVersion")"
workingDir=$(pwd)
echo "$scriptName :   workingDir      : $workingDir"
echo
echo "$scriptName : ---------------------"
echo "$scriptName : Remote Task Execution"
echo "$scriptName : ---------------------"

./$LOCAL_WORK_DIR/remoteTasks.sh "$ENVIRONMENT" "$BUILD" "$SOLUTION" "$LOCAL_WORK_DIR" "$OPT_ARG"
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Remote Deploy process failed! Returned $exitCode"
	echo "$scriptName : ./$LOCAL_WORK_DIR/remoteTasks.sh $ENVIRONMENT $BUILD $SOLUTION $LOCAL_WORK_DIR $OPT_ARG"
	exit $exitCode
fi
echo
echo "$scriptName : --------------------"
echo "$scriptName : Local Task Execution"
echo "$scriptName : --------------------"

./$LOCAL_WORK_DIR/localTasks.sh "$ENVIRONMENT" "$BUILD" "$SOLUTION" "$LOCAL_WORK_DIR" "$OPT_ARG"
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Remote Deploy process failed! Returned $exitCode"
	echo "$scriptName : ./$LOCAL_WORK_DIR/localTasks.sh $ENVIRONMENT $BUILD $SOLUTION $LOCAL_WORK_DIR $OPT_ARG"
	exit $exitCode
fi
