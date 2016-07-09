#!/bin/bash
# Emulate calling the package and deploy process as it would be from the automation toolset, 
# e.g. Bamboo or Jenkings, replacing BUILD with timestamp
# workspace with temp space. The variables provided in Jenkins are emulated in the scripts
# themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

SOLUTION="$1"
ENVIRONMENT="$2"
BUILD="$3"
REVISION="$4"
AUTOMATION_ROOT="$5"
LOCAL_WORK_DIR="$6"
REMOTE_WORK_DIR="$7"
ACTION="$8"

scriptName=${0##*/}

echo
echo "$scriptName : ===================================="
echo "$scriptName : Continuous Integration (CI) Starting"
echo "$scriptName : ===================================="
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
if [[ $REVISION == *'$'* ]]; then
	REVISION=$(eval echo $REVISION)
fi
echo "$scriptName :   REVISION        : $REVISION"
echo "$scriptName :   AUTOMATION_ROOT : $AUTOMATION_ROOT"
echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"
echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"
echo "$scriptName :   ACTION          : $ACTION"
echo "$scriptName :   pwd             : $(pwd)"
echo "$scriptName :   whoami          : $(whoami)"
echo "$scriptName :   CDAF Version    : $(./$AUTOMATION_ROOT/remote/getProperty.sh "$AUTOMATION_ROOT/CDAF.linux" "productVersion")"

./$AUTOMATION_ROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILD" "$REVISION" "$ENVIRONMENT" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo
	echo "$scriptName : Project Build Failed! ./$AUTOMATION_ROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILD" "$REVISION" "$ENVIRONMENT" "$ACTION". Halt with exit code = $exitCode. "
	exit $exitCode
fi
    
./$AUTOMATION_ROOT/buildandpackage/package.sh "$SOLUTION" "$BUILD" "$REVISION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo
	echo "$scriptName : Package Failed! Halt with exit code = $exitCode."
	exit $exitCode
fi
