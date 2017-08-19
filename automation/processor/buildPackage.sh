#!/bin/bash
# Entry point for building projects and packaging solution. 

scriptName=${0##*/}

echo
echo "$scriptName : ===================================="
echo "$scriptName : Continuous Integration (CI) Starting"
echo "$scriptName : ===================================="

# Processed out of order as needed for solution determination
AUTOMATION_ROOT="$5"
if [ -z $AUTOMATION_ROOT ]; then
	for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
		directoryName=${i%%/}
		if [ -f "$directoryName/CDAF.linux" ]; then
			AUTOMATION_ROOT="$directoryName"
			rootLogging="$AUTOMATION_ROOT (CDAF.linux found)"
		fi
	done
	if [ -z "$AUTOMATION_ROOT" ]; then
		AUTOMATION_ROOT="automation"
		rootLogging="$AUTOMATION_ROOT (CDAF.linux not found)"
	fi
fi

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ]; then
		solutionRoot="$directoryName"
	fi
done
if [ -z "$solutionRoot" ]; then
	solutionRoot="$AUTOMATION_ROOT/solution"
	solutionMessage="$solutionRoot (default, project directory containing CDAF.solution not found)"
else
	solutionMessage="$solutionRoot ($solutionRoot/CDAF.solution found)"
fi
echo "$scriptName :   solutionRoot    : $solutionMessage"

BUILDNUMBER="$1"
if [[ $BUILDNUMBER == *'$'* ]]; then
	BUILDNUMBER=$(eval echo $BUILDNUMBER)
fi
if [ -z $BUILDNUMBER ]; then
	echo "$scriptName : Build Number not passed! Exiting with code 1"; exit 1
fi
echo "$scriptName :   BUILDNUMBER     : $BUILDNUMBER"

REVISION="$2"
if [[ $REVISION == *'$'* ]]; then
	REVISION=$(eval echo $REVISION)
fi
if [ -z $REVISION ]; then
	REVISION='Revision'
	echo "$scriptName :   REVISION        : $REVISION (default)"
else
	echo "$scriptName :   REVISION        : $REVISION"
fi

ACTION="$3"
echo "$scriptName :   ACTION          : $ACTION"

SOLUTION="$4"
if [[ $SOLUTION == *'$'* ]]; then
	SOLUTION=$(eval echo $SOLUTION)
fi
if [ -z $SOLUTION ]; then
	SOLUTION=$($AUTOMATION_ROOT/remote/getProperty.sh "./$solutionRoot/CDAF.solution" "solutionName")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Read of SOLUTION from $solutionRoot/CDAF.solution failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "$scriptName :   SOLUTION        : $SOLUTION (derived from $solutionRoot/CDAF.solution)"
else
	echo "$scriptName :   SOLUTION        : $SOLUTION"
fi 

# Use passed argument to determine if a value was passed or if a default was set and used above
echo "$scriptName :   AUTOMATION_ROOT : $rootLogging"

LOCAL_WORK_DIR="$6"
if [ -z $LOCAL_WORK_DIR ]; then
	LOCAL_WORK_DIR='TasksLocal'
	echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR (default)"
else
	echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"
fi

REMOTE_WORK_DIR="$7"
if [ -z $REMOTE_WORK_DIR ]; then
	REMOTE_WORK_DIR='TasksRemote'
	echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR (default)"
else
	echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"	
fi

echo "$scriptName :   pwd             : $(pwd)"
echo "$scriptName :   hostname        : $(hostname)"
echo "$scriptName :   whoami          : $(whoami)"
echo "$scriptName :   CDAF Version    : $($AUTOMATION_ROOT/remote/getProperty.sh "$AUTOMATION_ROOT/CDAF.linux" "productVersion")"

$AUTOMATION_ROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo
	echo "$scriptName : Project(s) Build Failed! $AUTOMATION_ROOT/buildandpackage/buildProjects.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$ACTION\". Halt with exit code = $exitCode. "
	exit $exitCode
fi
    
$AUTOMATION_ROOT/buildandpackage/package.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo
	echo "$scriptName : Solution Package Failed! $AUTOMATION_ROOT/buildandpackage/package.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$LOCAL_WORK_DIR\" \"$REMOTE_WORK_DIR\" \"$ACTION\". Halt with exit code = $exitCode."
	exit $exitCode
fi
