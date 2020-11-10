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
	BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
	if [ -z "${BRANCH}" ]; then
		BRANCH='targetlesscd'
	fi
	echo "[$scriptName]   BRANCH         : $BRANCH (not passed, set to default)"
else
	if [[ $BRANCH == *'$'* ]]; then
		BRANCH=$(eval echo $BRANCH)
	fi
	echo "[$scriptName]   BRANCH         : $BRANCH"
	branchBase=${BRANCH##*/}                                # Retrieve basename
	BRANCH=$(sed 's/[^[:alnum:]]\+//g' <<< $branchBase)     # remove non-alphanumeric characters
	BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]') # make case insensitive
fi

ACTION="$3"
echo "[$scriptName]   ACTION         : $ACTION"

workspace=$(pwd)
echo "[$scriptName]   pwd            : $workspace"

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

if [ "$BRANCH" != 'master' ]; then
	artifactPrefix=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "artifactPrefix")
	unset CDAF_AUTOMATION_ROOT
	if [ -z "$artifactPrefix" ]; then
		executeExpression "./TasksLocal/delivery.sh DOCKER"
	else
		executeExpression "./release.sh DOCKER"
	fi
fi

echo
gitRemoteURL=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "gitRemoteURL")
if [[ $gitRemoteURL == *'$'* ]]; then
	SOLUTION=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "solutionName")
	gitRemoteURL=$(eval echo $gitRemoteURL)
fi
if [ -z "$gitRemoteURL" ]; then
	echo "[$scriptName] gitRemoteURL not defined in $solutionRoot/CDAF.solution, skipping ..."
else
	echo "[$scriptName] gitRemoteURL = ${gitRemoteURL}, perform branch cleanup ..."
	gitUserNameEnvVar=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "gitUserNameEnvVar")
	if [ -z "$gitUserNameEnvVar" ]; then
		echo "[$scriptName] gitRemoteURL defined, but gitUserNameEnvVar not defined, relying on current workspace being up to date"
	else
		userName=$(eval "echo $gitUserNameEnvVar")
		if [ -z "$userName" ]; then
			echo "[$scriptName] $gitUserNameEnvVar contains no value, relying on current workspace being up to date"
		else
			userName=${userName//@/%40}
			gitUserPassEnvVar=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "gitUserPassEnvVar")	
			if [ -z "$gitUserPassEnvVar" ]; then echo "[$scriptName] gitUserNameEnvVar defined, but gitUserPassEnvVar not defined in $solutionRoot/CDAF.solution!"; exit 6921; fi
			userPass=$(eval "echo $gitUserPassEnvVar")
			if [ -z "$userPass" ]; then
				echo "[$scriptName] $gitUserPassEnvVar contains no value, relying on current workspace being up to date"
			else
				gitRemoteURL=$(echo "https://${userName}:${userPass}@${gitRemoteURL//https:\/\/}")
			fi
		fi
	fi

	isGit=$(git log -n 1 --pretty=%d HEAD 2> /dev/null)
	if [ $? -eq 0 ]; then
		headAttached=$(echo "$isGit" | grep -e '->')
	fi
	if [ -z "${headAttached}" ]; then

		if [ -z "$userName" ]; then
			echo "[$scriptName] Workspace is not a Git repository or has detached head, but git credentials not set, skipping ..."; echo
			skipRemoteBranchCheck='yes'
		else
			if [ -z "$HOME" ]; then
				tempDir=$(echo "${TEMP}/.cdaf-cache")
			else
				tempDir=$(echo "${HOME}/.cdaf-cache")
			fi
			echo "[$scriptName] Workspace is not a Git repository or has detached head, skip branch clean-up and perform custom clean-up tasks in $tempDir ..."; echo
			executeExpression "mkdir -p $tempDir"
			executeExpression "cd $tempDir"
			repoName=${gitRemoteURL%/} # remove trailing /
			repoName=${repoName##*/}   # retrieve basename
			repoName=${repoName%.*}    # remove suffix
			if [ ! -d "$repoName" ]; then
				executeExpression "git clone '${gitRemoteURL}'"
			fi
			executeExpression "cd $repoName"
			executeExpression "git fetch --prune '${gitRemoteURL}'"
			usingCache=$(git log -n 1 --pretty=%d HEAD 2> /dev/null)
			if [ $? -ne 0 ]; then echo "[$scriptName] Git cache update failed!"; exit 6924; fi
			echo "$usingCache"
			echo "git branch '${branchBase}' 2> /dev/null"
			git branch "${branchBase}" 2> /dev/null
			git checkout -b "${branchBase}" 2> /dev/null # cater for ambiguous origin
			executeExpression "git checkout '${branchBase}' 2> /dev/null"
			gitName=$(git config --list | grep user.name=)
			if [ -z "$gitName" ]; then
				git config user.name "Your Name"
			fi
			gitEmail=$(git config --list | grep user.email=)
			if [ -z "$gitEmail" ]; then
				git config user.email "you@example.com"
			fi
			executeExpression "git pull origin '${branchBase}'"
		fi

	else

		echo; echo "$headAttached"; echo
		echo "[$scriptName] Refresh Remote branches"; echo
		if [ -z $userName ]; then
			executeExpression "git fetch --prune"
		else
			executeExpression "git fetch --prune '${gitRemoteURL}'"
		fi

	fi

	if [ -z "$skipRemoteBranchCheck" ]; then
		echo; echo "[$scriptName] Load Remote branches from local cache (git ls-remote --heads origin 2>/dev/null)"; echo
		for remoteBranch in $(git ls-remote --heads origin 2>/dev/null); do 
			remoteBranch=$(echo "$remoteBranch" | grep '/')
			if [ ! -z "${remoteBranch}" ]; then
				remoteBranch=${remoteBranch##*/} # trim to basename for compare
				remoteArray+=( "$remoteBranch" )
			fi
		done
		if [ -z "${remoteArray}" ]; then echo "[$scriptName] git ls-remote --heads origin provided no branches!"; exit 6925; fi

		for remoteBranch in ${remoteArray[@]}; do # verify array contents
			echo "  ${remoteBranch}"
		done

		echo; echo "[$scriptName] Process Local branches (git branch --format='%(refname:short)')"; echo
		for localBranch in $(git branch --format='%(refname:short)'); do
			branchName=${localBranch##*/}  # retrieve basename for compare
			if [[ " ${remoteArray[@]} " =~ " ${branchName} " ]]; then
				echo "  keep branch ${localBranch}"
			else
				executeExpression "  git branch -D '${localBranch}'"
			fi
		done

		echo
		gitCustomCleanup=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "gitCustomCleanup")
		if [ -z ${gitCustomCleanup} ]; then
			echo "[$scriptName] gitCustomCleanup not defined in $solutionRoot/CDAF.solution, skipping ..."
		else
			solutionName=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "solutionName")
			argList="'${solutionName}'"
			for remoteBranch in "${remoteArray[@]}"; do
				argList="${argList} '${remoteBranch}'"
			done
			executeExpression "$gitCustomCleanup ${argList}"
		fi
	fi
fi

if [ ! -z "${usingCache}" ]; then
	executeExpression "cd $workspace"
fi
echo; echo "[$scriptName] ---------- stop ----------"
exit 0
