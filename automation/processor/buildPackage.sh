#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

# Entry point for building projects and packaging solution. 

scriptName=${0##*/}

echo
echo "$scriptName : ===================================="
echo "$scriptName : Continuous Integration (CI) Starting"
echo "$scriptName : ===================================="

echo "$scriptName :   pwd             : $(pwd)"
echo "$scriptName :   hostname        : $(hostname)"
echo "$scriptName :   whoami          : $(whoami)"

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
for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
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
caseinsensitive=$(echo "$ACTION" | tr '[A-Z]' '[a-z]')

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

echo "$scriptName :   CDAF Version    : $($AUTOMATION_ROOT/remote/getProperty.sh "$AUTOMATION_ROOT/CDAF.linux" "productVersion")"

# If a container build command is specified, use this instead of CI process
containerBuild=$($AUTOMATION_ROOT/remote/getProperty.sh "./$solutionRoot/CDAF.solution" "containerBuild")
if [ -n "$containerBuild" ]; then
	test=$(docker --version 2>&1)
	if [[ "$test" == *"not found"* ]]; then
		echo "$scriptName :   Docker          : container Build defined in $solutionRoot/CDAF.solution, but Docker not installed, will attempt to execute natively"
		unset containerBuild
	else
		IFS=' ' read -ra ADDR <<< $test
		IFS=',' read -ra ADDR <<< ${ADDR[2]}
		dockerRun="${ADDR[0]}"
		echo "$scriptName :   Docker          : $dockerRun"
	fi
else
	echo "$scriptName :   containerBuild  : (not defined in $solutionRoot/CDAF.solution)"
fi

# CDAF 1.7.0 Container Build process
if [ -n "$containerBuild" ] && [ "$caseinsensitive" != "clean" ]; then
	echo
	echo "$scriptName Execute Container build, this performs cionly, options packageonly and buildonly are ignored."
	executeExpression "$containerBuild"

	imageBuild=$($AUTOMATION_ROOT/remote/getProperty.sh "./$solutionRoot/CDAF.solution" "imageBuild")
	if [ -n "$containerBuild" ]; then
		echo
		echo "$scriptName Execute Image build, as defined for imageBuild in $solutionRoot\CDAF.solution"
		executeExpression "$imageBuild"
	else
		echo "$scriptName :   imageBuild      : (not defined in $solutionRoot/CDAF.solution)"
	fi
else
	if [ "$caseinsensitive" == "packageonly" ]; then
		echo "$scriptName action is ${ACTION}, do not perform build."
	else
		$AUTOMATION_ROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$ACTION"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo
			echo "$scriptName : Project(s) Build Failed! $AUTOMATION_ROOT/buildandpackage/buildProjects.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$ACTION\". Halt with exit code = $exitCode. "
			exit $exitCode
		fi
	fi
	
	if [ "$caseinsensitive" == "buildonly" ]; then
		echo "$scriptName action is ${ACTION}, do not perform package."
	else
		$AUTOMATION_ROOT/buildandpackage/package.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR" "$ACTION"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo
			echo "$scriptName : Solution Package Failed! $AUTOMATION_ROOT/buildandpackage/package.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$LOCAL_WORK_DIR\" \"$REMOTE_WORK_DIR\" \"$ACTION\". Halt with exit code = $exitCode."
			exit $exitCode
		fi
	fi
fi