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
scriptName='entry.sh'

echo; echo "[$scriptName] ---------- start ----------"
AUTOMATIONROOT="$( cd "$(dirname "$0")" ; pwd -P )"
echo "[$scriptName]   AUTOMATIONROOT : $AUTOMATIONROOT"
export CDAF_AUTOMATION_ROOT=$AUTOMATIONROOT

BUILDNUMBER="$1"
if [ -z $BUILDNUMBER ]; then
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
if [[ $BRANCH == *'$'* ]]; then
	BRANCH=$(eval echo $BRANCH)
fi
BRANCH=${BRANCH##*/}
BRANCH=${BRANCH//\#}
if [ -z $BRANCH ]; then
	BRANCH='targetlesscd'
	echo "[$scriptName]   BRANCH         : $BRANCH (not passed, set to default)"
else
	echo "[$scriptName]   BRANCH         : $BRANCH"
fi

ACTION="$3"
echo "[$scriptName]   ACTION         : $ACTION"

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "[$scriptName]   solutionRoot   : "
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

executeExpression "$AUTOMATIONROOT/processor/buildPackage.sh '$BUILDNUMBER' '$BRANCH' '$ACTION'"

if [ $BRANCH != 'master' ]; then
	artifactPrefix=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "artifactPrefix")
	unset CDAF_AUTOMATION_ROOT
	if [ -z $artifactPrefix ]; then
		executeExpression "./TasksLocal/delivery.sh DOCKER"
	else
		executeExpression "./release.sh DOCKER"
	fi
fi

if [[ "$ACTION" == "remoteURL@"* ]]; then

	defaultIFS=$IFS
	IFS='@' read -ra arr <<< $ACTION
	if [ -z ${arr[1]} ]; then
		echo "[$scriptName] Remote URL not provided, will attempt to use local cache"
	else
		remoteURL="${arr[1]}"
		echo "[$scriptName] ACTION ($ACTION) prefix is remoteURL@, attempt remote branch synchronisation using $remoteURL"

		gitUserNameEnvVar=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "gitUserNameEnvVar")
		if [ -z $gitUserNameEnvVar ]; then echo "[$scriptName] gitUserNameEnvVar not defined in $solutionRoot/CDAF.solution!"; exit 6921; fi
		userName=$(eval "echo $gitUserNameEnvVar")
		if [ -z $userName ]; then echo "[$scriptName] $gitUserNameEnvVar contains no value!"; exit 6921; fi
		userName=${userName//@/%40}

		gitUserPassEnvVar=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "gitUserPassEnvVar")	
		if [ -z $gitUserPassEnvVar ]; then echo "[$scriptName] gitUserNameEnvVar not defined in $solutionRoot/CDAF.solution!"; exit 6921; fi
		userPass=$(eval "echo $gitUserPassEnvVar")
		if [ -z $userPass ]; then echo "[$scriptName] $gitUserPassEnvVar contains no value!"; exit 6921; fi

		echo; echo "[$scriptName] Refresh Remote branches"; echo

		remoteURL=$(echo "https://${userName}:${userPass}@${remoteURL//https:\/\/}")
		executeExpression "git fetch --prune ${remoteURL}"
	fi

	echo; echo "[$scriptName] Load Remote branches from local cache"; echo
	for remoteBranch in $(git ls-remote 2>/dev/null); do 
		remoteBranch=$(echo "$remoteBranch" | grep 'refs/heads/')
		if [ ! -z "${remoteBranch}" ]; then
			remoteBranch=${remoteBranch//refs\/heads\/}
			remoteArray+=( "$remoteBranch" )
		fi
	done
	for remoteBranch in ${remoteArray[@]}; do # verify array contents
		echo "      ${remoteBranch}"
	done

	echo; echo "[$scriptName] Process Local branches (git branch)"; echo
	git branch

	echo
	branchList=$(git branch)
	branchList=${branchList//\*}
	branchList=${branchList// }
	for localBranch in $branchList; do
		if [[ ! " ${remoteArray[@]} " =~ " ${localBranch} " ]]; then
			executeExpression "git branch -D '${localBranch}'"
		fi
	done

	echo; echo "[$scriptName] List local branches after clean-up (git branch)"; echo
	git branch
fi

echo; echo "[$scriptName] ---------- stop ----------"
exit 0
