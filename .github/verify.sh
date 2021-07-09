#!/bin/bash

scriptName='verify.sh'

function ERRMSG {
	# Shared function for internal user processing
	#  required : directory name
	#  optional : exit code, if not supplied on error message is written
	if [ -z "$2" ]; then
		echo; echo "[$scriptName][WARN] $1"
	else
		echo; echo "[$scriptName][ERROR] $1"
	fi
	if [ ! -z $CDAF_ERROR_DIAG ]; then
		echo; echo "[$scriptName] Invoke custom diag CDAF_ERROR_DIAG = $CDAF_ERROR_DIAG"; echo
		eval "$CDAF_ERROR_DIAG"
	fi
	if [ ! -z "$2" ]; then
		echo; echo "[$scriptName] Exit with LASTEXITCODE = $exitcode" ; echo
		exit $2
	fi
}

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		ERRMSG "[EXCEPTION] $EXECUTABLESCRIPT returned $exitCode" $exitCode
	fi
}  

echo; echo "[$scriptName] ---------- start ----------"

BUILDNUMBER="$1"
if [ -z "$BUILDNUMBER" ]; then
	# Use a simple text file (${HOME}/buildnumber.counter) for incremental build number
	if [ -f "${HOME}/buildnumber.counter" ]; then
		let "BUILDNUMBER=$(cat ${HOME}/buildnumber.counter|tr -d '\r')" # in case the home directory is shared by Windows and Linux
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
if [ -z "$BRANCH" ]; then
	if [ -z "$CDAF_BRANCH_NAME" ]; then
		BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
		if [ -z "${BRANCH}" ]; then
			BRANCH='targetlesscd'
		fi
		echo "[$scriptName]   BRANCH         : $BRANCH (not passed, set to default)"
	else
		BRANCH="$CDAF_BRANCH_NAME"
		skipBranchCleanup='yes'
		echo "[$scriptName]   BRANCH         : $BRANCH (not supplied, derived from \$CDAF_BRANCH_NAME)"
	fi
else
	if [[ $BRANCH == *'$'* ]]; then
		BRANCH=$(eval echo $BRANCH)
	fi
	echo "[$scriptName]   BRANCH         : $BRANCH"
	branchBase=${BRANCH##*/}                                # Retrieve basename
	BRANCH=$(sed 's/[^[:alnum:]]\+//g' <<< $branchBase)     # remove non-alphanumeric characters
	BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]') # make case insensitive
fi

if [ -d './solution' ]; then
    executeExpression 'rm -rf ./solution'
fi

executeExpression 'cp -rf automation/solution .'

echo "automation" > ./solution/storeForLocal
executeExpression 'cat ./solution/storeForLocal'

echo "REMOVE ~/.cdaf" > ./solution/custom/cdaf-deploy.tsk
echo "VECOPY automation ~/.cdaf" >> ./solution/custom/cdaf-deploy.tsk
executeExpression 'cat ./solution/custom/cdaf-deploy.tsk'

echo "context  target     deployTaskOverride" > ./solution/cdaf.cm
echo "local    CDAF       cdaf-deploy.tsk" >> ./solution/cdaf.cm
executeExpression 'echo "cat ./solution/cdaf.cm"'

executeExpression "./automation/ci.sh $BUILDNUMBER $BRANCH"
