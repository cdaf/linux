#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$scriptName : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

# Entry point for branch based targetless CD

scriptName=${0##*/}

echo
echo "$scriptName : ===================="
echo "$scriptName : Targetless Branch CD"
echo "$scriptName : ===================="
automationRoot="$( cd "$(dirname "$0")" ; pwd -P )"
echo "$scriptName :   AUTOMATIONROOT : $AUTOMATIONROOT"
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
	echo "$scriptName :   BUILDNUMBER    : $BUILDNUMBER (not passed, using local counterfile ${HOME}/buildnumber.counter)"
else
	echo "$scriptName :   BUILDNUMBER    : $BUILDNUMBER"
fi

BRANCH="$2"
if [ -z $BRANCH ]; then
	BRANCH='targetlesscd'
	echo "$scriptName :   BRANCH         : $BRANCH (not passed, set to default)"
else
	echo "$scriptName :   BRANCH         : $BRANCH"
fi

executeExpression "$AUTOMATIONROOT/processor/buildPackage.sh $BUILDNUMBER $BRANCH"

if [ $BRANCH != 'master' ]; then
	executeExpression "./TasksLocal/delivery.sh DOCKER"
fi

echo; echo "$scriptName : Continuous Integration (CI) Finished"
exit 0
