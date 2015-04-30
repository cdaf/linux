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
echo "$scriptName : ==========================================="
echo "$scriptName : Continuous Delivery (CD) Emulation Starting"
echo "$scriptName : ==========================================="
echo "$scriptName :   SOLUTION        : $SOLUTION"
echo "$scriptName :   ENVIRONMENT     : $ENVIRONMENT"
echo "$scriptName :   BUILD           : $BUILD"
echo "$scriptName :   REVISION        : $REVISION"
echo "$scriptName :   AUTOMATION_ROOT : $AUTOMATION_ROOT"
echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"
echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"
echo "$scriptName :   ACTION          : $ACTION"
echo
echo "$scriptName : ---------------------"
echo "$scriptName : Remote Task Execution"
echo "$scriptName : ---------------------"
echo
echo "$scriptName : ---------- CD Toolset Configuration Guide -------------"
echo
echo "$scriptName : For TeamCity ..."
echo "  Command Executable : /$LOCAL_WORK_DIR/remoteTasks.sh" 
echo "  Command parameters : $ENVIRONMENT %build.number% $SOLUTION $LOCAL_WORK_DIR"
echo
echo "$scriptName : For Bamboo ..."
echo "  Script file : \${bamboo.build.working.directory}/$LOCAL_WORK_DIR/remoteTasks.sh"
echo "  Argument : \${bamboo.deploy.environment} \${bamboo.buildNumber} \${bamboo.deploy.project} $LOCAL_WORK_DIR"
echo
echo "$scriptName : For Jenkins ..."
echo "  Command : /$LOCAL_WORK_DIR/remoteTasks.sh $ENVIRONMENT %BUILD_NUMBER% $SOLUTION $LOCAL_WORK_DIR"
echo
echo "$scriptName : -------------------------------------------------------"

./$LOCAL_WORK_DIR/remoteTasks.sh "$ENVIRONMENT" "$BUILD" "$SOLUTION" "$LOCAL_WORK_DIR"
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Remote Deploy process failed! Returned $exitCode"
	exit $exitCode
fi
echo
echo "$scriptName : --------------------"
echo "$scriptName : Local Task Execution"
echo "$scriptName : --------------------"
echo
echo "$scriptName : ---------- CD Toolset Configuration Guide -------------"
echo
echo "$scriptName : For TeamCity ..."
echo "  Command Executable : /$LOCAL_WORK_DIR/localTasks.sh"
echo "  Command parameters : $ENVIRONMENT %build.number% $SOLUTION $LOCAL_WORK_DIR"
echo
echo "$scriptName : For Bamboo ..."
echo "  Script file : \${bamboo.build.working.directory}/$LOCAL_WORK_DIR/localTasks.sh"
echo "  Argument : \${bamboo.deploy.environment} \${bamboo.buildNumber} \${bamboo.deploy.project} $LOCAL_WORK_DIR"
echo
echo "$scriptName : For Jenkins ..."
echo "  Command : /$LOCAL_WORK_DIR/localTasks.sh $ENVIRONMENT %BUILD_NUMBER% $SOLUTION $LOCAL_WORK_DIR"
echo
echo "$scriptName : -------------------------------------------------------"

./$LOCAL_WORK_DIR/localTasks.sh "$ENVIRONMENT" "$BUILD" "$SOLUTION" "$LOCAL_WORK_DIR"
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Remote Deploy process failed! Returned $exitCode"
	exit $exitCode
fi
