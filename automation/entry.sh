#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

# Entry point for branch based targetless CD
scriptName=${0##*/}

echo; echo "[$scriptName] ===================="
echo "[$scriptName] Targetless Branch CD"
echo "[$scriptName] ===================="
AUTOMATIONROOT="$( cd "$(dirname "$0")" ; pwd -P )"
echo "[$scriptName]   AUTOMATIONROOT  : $AUTOMATIONROOT"
export CDAF_AUTOMATION_ROOT=$AUTOMATIONROOT

BUILDNUMBER="$1"
if [ -z $BUILDNUMBER ]; then
	# Use a simple text file (${HOME}/buildnumber.counter) for incremental build number
	if [ -f "${HOME}/buildnumber.counter" ]; then
		let "BUILDNUMBER=$(cat ${HOME}/buildnumber.counter)"
	else
		let "BUILDNUMBER=0"
	fi
	if [ "$caseinsensitive" != "cdonly" ]; then
		let "BUILDNUMBER=$BUILDNUMBER + 1"
	fi
	echo $BUILDNUMBER > ${HOME}/buildnumber.counter
	echo "[$scriptName]   BUILDNUMBER  : $BUILDNUMBER (not passed, using local counterfile ${HOME}/buildnumber.counter)"
else
	echo "[$scriptName]   BUILDNUMBER  : $BUILDNUMBER"
fi

BRANCH="$2"
if [ -z $BRANCH ]; then
	BRANCH='targetlesscd'
	echo "[$scriptName]   BRANCH       : $BRANCH (not passed, set to default)"
else
	echo "[$scriptName]   BRANCH       : $BRANCH"
fi

ACTION="$3"
echo "[$scriptName]   ACTION       : $ACTION"

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "[$scriptName]   solutionRoot : "
for directoryName in $(find . -maxdepth 1 -mindepth 1 -type d); do
	if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
		solutionRoot="$directoryName"
	fi
done
if [ -z "$solutionRoot" ]; then
	solutionRoot="$automationRoot/solution"
	echo "$solutionRoot (default, project directory containing CDAF.solution not found)"
else
	echo "$solutionRoot (override $solutionRoot/CDAF.solution found)"
fi

executeExpression "$AUTOMATIONROOT/processor/buildPackage.sh $BUILDNUMBER $BRANCH $ACTION"

if [ $BRANCH != 'master' ]; then
	artifactPrefix=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "artifactPrefix")
	if [ -z $artifactPrefix ]; then
		executeExpression "./TasksLocal/delivery.sh DOCKER"
	else
		executeExpression "./release.sh DOCKER"
	fi
fi

echo; echo "[$scriptName] Continuous Integration (CI) Finished"
exit 0
