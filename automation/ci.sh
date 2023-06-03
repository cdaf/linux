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

scriptName='ci.sh'

echo
echo "[$scriptName] ======================"
echo "[$scriptName] Continuous Integration"
echo "[$scriptName] ======================"
AUTOMATIONROOT="$( cd "$(dirname "$0")" && pwd )"
echo "[$scriptName]   AUTOMATIONROOT : $AUTOMATIONROOT"
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
	echo "[$scriptName]   BUILDNUMBER    : $BUILDNUMBER (not passed, using local counterfile ${HOME}/buildnumber.counter)"
else
	echo "[$scriptName]   BUILDNUMBER    : $BUILDNUMBER"
fi

BRANCH="$2"
if [[ $BRANCH == *'$'* ]]; then
	BRANCH=$(eval echo $BRANCH)
fi
if [ -z $BRANCH ]; then
	BRANCH='revision'
	echo "[$scriptName]   BRANCH         : $BRANCH (not passed, set to default)"
else
	origRev="${BRANCH}"
	BRANCH=${BRANCH##*/}                                    # strip to basename
	BRANCH=$(sed 's/[^[:alnum:]]\+//g' <<< $BRANCH)         # remove non-alphanumeric characters
	BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]') # make case insensitive
	if [ "${origRev}" != "${BRANCH}" ]; then
		echo "[$scriptName]   BRANCH         : (cleansed from $origRev)"
	else
		echo "[$scriptName]   BRANCH         : $BRANCH"
	fi
fi

ACTION="$3"
echo "[$scriptName]   ACTION         : $ACTION"

executeExpression "$AUTOMATIONROOT/processor/buildPackage.sh '$BUILDNUMBER' '$BRANCH' '$ACTION'"
exit 0
