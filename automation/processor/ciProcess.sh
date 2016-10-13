#!/bin/bash
# Emulate calling the package and deploy process as it would be from the automation toolset, 
# e.g. Bamboo or Jenkings, replacing BUILD with timestamp
# workspace with temp space. The variables provided in Jenkins are emulated in the scripts
# themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

BUILD="$1"
REVISION="$2"
ACTION="$3"
SOLUTION="$4"
AUTOMATION_ROOT="$5"
LOCAL_WORK_DIR="$6"
REMOTE_WORK_DIR="$7"

scriptName=${0##*/}

echo
echo "$scriptName : ===================================="
echo "$scriptName : Continuous Integration (CI) Starting"
echo "$scriptName : ===================================="

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "$scriptName :   solutionRoot    : "
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ]; then
		solutionRoot="$directoryName"
	fi
done
if [ -z "$solutionRoot" ]; then
	solutionRoot="$automationRoot/solution"
	echo "$solutionRoot (default, project directory containing CDAF.solution not found)"
else
	echo "$solutionRoot ($solutionRoot/CDAF.solution found)"
fi

if [[ $BUILD == *'$'* ]]; then
	BUILD=$(eval echo $BUILD)
fi
if [ -z $BUILD ]; then
	echo "$scriptName : Build Number not passed! Exiting with code 1"; exit 1
fi
echo "$scriptName :   BUILD           : $BUILD"

if [[ $REVISION == *'$'* ]]; then
	REVISION=$(eval echo $REVISION)
fi
if [ -z $REVISION ]; then
	REVISION='Revision'
fi
echo "$scriptName :   REVISION        : $REVISION"

if [ -z $ACTION ]; then
	ACTION='BUILD'
	echo "$scriptName :   ACTION          : $ACTION (default)"
else
	echo "$scriptName :   ACTION          : $ACTION"
fi

if [ -z $AUTOMATION_ROOT ]; then
	AUTOMATION_ROOT='automation'
fi
if [[ $SOLUTION == *'$'* ]]; then
	SOLUTION=$(eval echo $SOLUTION)
fi
if [ -z $SOLUTION ]; then
	SOLUTION=$(./$AUTOMATION_ROOT/remote/getProperty.sh "./$solutionRoot/CDAF.solution" "solutionName")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Read of SOLUTION from ./solutionRoot/CDAF.solution failed! Returned $exitCode"
		exit $exitCode
	fi
fi 
echo "$scriptName :   SOLUTION        : $SOLUTION"

echo "$scriptName :   AUTOMATION_ROOT : $AUTOMATION_ROOT"

if [ -z $LOCAL_WORK_DIR ]; then
	LOCAL_WORK_DIR='TasksLocal'
fi
echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"

if [ -z $REMOTE_WORK_DIR ]; then
	REMOTE_WORK_DIR='TasksRemote'
fi
echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"

echo "$scriptName :   pwd             : $(pwd)"
echo "$scriptName :   whoami          : $(whoami)"
echo "$scriptName :   CDAF Version    : $(./$AUTOMATION_ROOT/remote/getProperty.sh "$AUTOMATION_ROOT/CDAF.linux" "productVersion")"

./$AUTOMATION_ROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILD" "$REVISION" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo
	echo "$scriptName : Project(s) Build Failed! ./$AUTOMATION_ROOT/buildandpackage/buildProjects.sh \"$SOLUTION\" \"$BUILD\" \"$REVISION\" \"$ACTION\". Halt with exit code = $exitCode. "
	exit $exitCode
fi
    
./$AUTOMATION_ROOT/buildandpackage/package.sh "$SOLUTION" "$BUILD" "$REVISION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo
	echo "$scriptName : Solution Package Failed! ./$AUTOMATION_ROOT/buildandpackage/package.sh \"$SOLUTION\" \"$BUILD\" \"$REVISION\" \"$LOCAL_WORK_DIR\" \"$REMOTE_WORK_DIR\" \"$ACTION\". Halt with exit code = $exitCode."
	exit $exitCode
fi
