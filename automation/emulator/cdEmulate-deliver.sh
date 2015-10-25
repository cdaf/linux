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
echo "Configure artefact retention patterns to retain package and local tasks"
echo "   *.zip" 
echo "  TasksLocal/**"
echo
echo "  set the first step of deploy to make scripts executable"
echo "  chmod +x ./*/*.sh"
echo
echo "For TeamCity ..."
echo "  Command Executable : /$LOCAL_WORK_DIR/remoteTasks.sh" 
echo "  Command parameters : $ENVIRONMENT %build.number% $SOLUTION $LOCAL_WORK_DIR"
echo
echo "For Go (requires explicit bash invoke) ..."
echo "  Command   : /bin/bash"
echo "  Arguments : -c '/$LOCAL_WORK_DIR/remoteTasks.sh ${GO_ENVIRONMENT_NAME} \${GO_PIPELINE_COUNTER} $SOLUTION $LOCAL_WORK_DIR'"
echo
echo "For Bamboo ... (Beware! set Deployment project name to solution name, with no spaces)"
echo "  Script file : \${bamboo.build.working.directory}/$LOCAL_WORK_DIR/remoteTasks.sh"
echo "  Argument : \${bamboo.deploy.environment} \${bamboo.buildNumber} \${bamboo.deploy.project} $LOCAL_WORK_DIR"
echo
echo "  note: set the release tag to (assuming no releases performed, otherwise, use the release number already set)"
echo "  build-${bamboo.buildNumber} deploy-1"
echo
echo "For Jenkins ..."
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
echo "$scriptName : For Go (requires explicit bash invoke) ..."
echo "  Command   : /bin/bash"
echo "  Arguments : -c '/$LOCAL_WORK_DIR/localTasks.sh ${GO_ENVIRONMENT_NAME} \${GO_PIPELINE_COUNTER} $SOLUTION $LOCAL_WORK_DIR'"
echo
echo "For Bamboo ... (Beware! set Deployment project name to solution name, with no spaces)"
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
