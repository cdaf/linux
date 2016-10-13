#!/bin/bash
# Emulate calling the package and deploy process as it would be from the automation toolset, 
# e.g. Bamboo or Jenkings, replacing BUILD with timestamp
# workspace with temp space. The variables provided in Jenkins are emulated in the scripts
# themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

ENVIRONMENT="$1"
RELEASE="$2"
OPT_ARG="$3"
BUILD="$4"
SOLUTION="$5"
LOCAL_WORK_DIR="$6"
REMOTE_WORK_DIR="$7"

scriptName=${0##*/}

echo
echo "$scriptName : ================================="
echo "$scriptName : Continuous Delivery (CD) Starting"
echo "$scriptName : ================================="

if [ -z $LOCAL_WORK_DIR ]; then
	LOCAL_WORK_DIR='TasksLocal'
fi 

if [ -z $REMOTE_WORK_DIR ]; then
	REMOTE_WORK_DIR='TasksRemote'
fi 

if [[ $ENVIRONMENT == *'$'* ]]; then
	ENVIRONMENT=$(eval echo $ENVIRONMENT)
fi
if [ -z $ENVIRONMENT ]; then
	echo "$scriptName : Environment required! EXiting code 1"; exit 1
fi 

echo "$scriptName :   ENVIRONMENT     : $ENVIRONMENT"

if [[ $RELEASE == *'$'* ]]; then
	RELEASE=$(eval echo $RELEASE)
fi
if [ -z $RELEASE ]; then
	RELEASE='Release'
fi 
echo "$scriptName :   RELEASE         : $RELEASE"
echo "$scriptName :   OPT_ARG         : $OPT_ARG"

if [[ $SOLUTION == *'$'* ]]; then
	SOLUTION=$(eval echo $SOLUTION)
fi
if [ -z $SOLUTION ]; then
	SOLUTION=$(./$LOCAL_WORK_DIR/getProperty.sh "./$LOCAL_WORK_DIR/manifest.txt" "SOLUTION")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Read of SOLUTION from ./$LOCAL_WORK_DIR/manifest.txt failed! Returned $exitCode"
		exit $exitCode
	fi
fi 
echo "$scriptName :   SOLUTION        : $SOLUTION"

if [[ $BUILD == *'$'* ]]; then
	BUILD=$(eval echo $BUILD)
fi
if [ -z $BUILD ]; then
	BUILD=$(./$LOCAL_WORK_DIR/getProperty.sh "./$LOCAL_WORK_DIR/manifest.txt" "BUILD")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Read of BUILD from ./$LOCAL_WORK_DIR/manifest.txt failed! Returned $exitCode"
		exit $exitCode
	fi
fi 
echo "$scriptName :   BUILD           : $BUILD"

echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"
echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"
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
