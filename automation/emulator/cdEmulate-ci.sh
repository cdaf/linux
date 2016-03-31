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
echo "$scriptName : =============================================="
echo "$scriptName : Continuous Integration (CI) Emulation Starting"
echo "$scriptName : =============================================="
echo "$scriptName :   SOLUTION        : $SOLUTION"
echo "$scriptName :   ENVIRONMENT     : $ENVIRONMENT"
echo "$scriptName :   BUILD           : $BUILD"
echo "$scriptName :   REVISION        : $REVISION"
echo "$scriptName :   AUTOMATION_ROOT : $AUTOMATION_ROOT"
echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"
echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"
echo "$scriptName :   ACTION          : $ACTION"

if [ -z "$ACTION" ]; then
	echo
	echo "$scriptName : ---------- CI Toolset Configuration Guide -------------"
	echo
    echo "$scriptName : For TeamCity ..."
    echo "  Command Executable : $AUTOMATION_ROOT/buildandpackage/buildProjects.sh"
    echo "  Command parameters : $SOLUTION %build.number% %build.vcs.number% BUILD"
    echo
    echo "$scriptName : For Go (requires explicit bash invoke) ..."
    echo "  Command   : /bin/bash"
    echo "  Arguments : -c 'automation/buildandpackage/buildProjects.sh $SOLUTION \${GO_PIPELINE_COUNTER} \${GO_REVISION} BUILD'"
    echo
    echo "$scriptName : For Bamboo ..."
    echo "  Script file : $AUTOMATION_ROOT/buildandpackage/buildProjects.sh"
	echo "  Argument    : $SOLUTION \${bamboo.buildNumber} \${bamboo.repository.revision.number} BUILD"
    echo
    echo "$scriptName : For Jenkins ..."
    echo "  Command : $AUTOMATION_ROOT/buildandpackage/buildProjects.sh $SOLUTION %BUILD_NUMBER% %SVN_REVISION% BUILD"
    echo
	echo "$scriptName : -------------------------------------------------------"
fi

./$AUTOMATION_ROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILD" "$REVISION" "$ENVIRONMENT" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo
	echo "$scriptName : Project Build Failed! ./$AUTOMATION_ROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILD" "$REVISION" "$ENVIRONMENT" "$ACTION". Halt with exit code = $exitCode. "
	exit $exitCode
fi

if [ -z "$ACTION" ]; then
	echo
	echo "$scriptName : ---------- CI Toolset Configuration Guide -------------"
	echo
	echo "$scriptName : For TeamCity ..."
    echo "  Command Executable : $AUTOMATION_ROOT/buildandpackage/package.sh" 
    echo "  Command parameters : $SOLUTION %build.number% %build.vcs.number% $LOCAL_WORK_DIR $REMOTE_WORK_DIR"
    echo
    echo "$scriptName : For Go (requires explicit bash invoke) ..."
    echo "  Command   : /bin/bash"
    echo "  Arguments : -c 'automation/buildandpackage/package.sh $SOLUTION \${GO_PIPELINE_COUNTER} \${GO_REVISION} $LOCAL_WORK_DIR $REMOTE_WORK_DIR'"
    echo
    echo "$scriptName : For Bamboo ..."
    echo "  Script file : $AUTOMATION_ROOT/buildandpackage/package.sh"
	echo "  Argument    : $SOLUTION \${bamboo.buildNumber} \${bamboo.repository.revision.number} $LOCAL_WORK_DIR $REMOTE_WORK_DIR"
    echo
    echo "$scriptName : For Jenkins ..."
    echo "  Command : $AUTOMATION_ROOT/buildandpackage/package.sh $SOLUTION %BUILD_NUMBER% %SVN_REVISION% $LOCAL_WORK_DIR $REMOTE_WORK_DIR"
    echo
	echo "$scriptName : -------------------------------------------------------"
fi
    
./$AUTOMATION_ROOT/buildandpackage/package.sh "$SOLUTION" "$BUILD" "$REVISION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo
	echo "$scriptName : Package Failed! Halt with exit code = $exitCode."
	exit $exitCode
fi

if [ -z "$ACTION" ]; then
	echo
	echo "$scriptName : ---------- CI Toolset Configuration Guide -------------"
	echo
	echo "Configure artefact retention patterns to retain package and local tasks"
	echo
    echo "$scriptName : For Bamboo ..."
    echo "  Name    : Package"
	echo "  Pattern : *.gz"
	echo
    echo "  Name    : TasksLocal"
	echo "  Pattern : TasksLocal/**"
	echo
	echo "$scriptName : -------------------------------------------------------"
fi

