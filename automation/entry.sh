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

function executeSuppress {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 will trigger a warning, but will continue
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][WARN] $1 returned $exitCode"
	fi
}  

# Consolidated Error processing function
#  required : error message
#  optional : exit code, if not supplied only error message is written
function ERRMSG {
	if [ -z "$2" ]; then
		echo; echo "[$scriptName][WARN]$1"
	else
		echo; echo "[$scriptName][ERROR]$1"
	fi
	if [ ! -z $CDAF_ERROR_DIAG ]; then
		echo; echo "[$scriptName] Invoke custom diag CDAF_ERROR_DIAG = $CDAF_ERROR_DIAG"; echo
		eval "$CDAF_ERROR_DIAG"
	fi
	if [ ! -z "$2" ]; then
		echo; echo "[$scriptName] Exit with LASTEXITCODE = $2" ; echo
		exit $2
	fi
}

# Entry point for branch based targetless CD
scriptName='entry.sh'

echo; echo "[$scriptName] ---------- start ----------"
AUTOMATIONROOT="$( cd "$(dirname "$0")" && pwd )"
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

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "[$scriptName]   SOLUTIONROOT   : "
for directoryName in $(find . -maxdepth 1 -mindepth 1 -type d); do
	if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
		SOLUTIONROOT="$directoryName"
	fi
done
if [ -z "$SOLUTIONROOT" ]; then
	ERRMSG "[NO_SOLUTION_ROOT] No directory found containing CDAF.solution, please create a single occurance of this file." 7610
else
	echo "$SOLUTIONROOT (override $SOLUTIONROOT/CDAF.solution found)"
fi

echo; echo "[$scriptName] Load Solution Properties $SOLUTIONROOT/CDAF.solution"
propertiesList=$($AUTOMATIONROOT/remote/transform.sh "$SOLUTIONROOT/CDAF.solution")
echo "$propertiesList"
eval $propertiesList

if ! [ -z "$CDAF_DELIVERY" ]; then
	environment="$CDAF_DELIVERY"
fi
if [ -z "$environment" ]; then
	if [ -z "$defaultEnvironment" ]; then
		environment='DOCKER'
		echo; echo "[$scriptName]   environment    : $environment (not set, default applied)"
	else
		environment=$(eval "echo $defaultEnvironment")
		echo; echo "[$scriptName]   environment    : $environment (loaded defaultEnvironment property)"
	fi	
else
	echo "[$scriptName]   environment    : $environment (from CDAF_DELIVERY environment variable)"
fi

if [ -z ${solutionName} ]; then
	ERRMSG "[NO_SOLUTION_NAME]   solutionName not defined!" 7762 
else
	SOLUTION=$solutionName
	echo "[$scriptName]   SOLUTION       : $SOLUTION"
fi

workspace=$(pwd)
echo "[$scriptName]   pwd            : $workspace"
echo "[$scriptName]   hostname       : $(hostname)"
echo "[$scriptName]   whoami         : $(whoami)"; echo

executeExpression "$AUTOMATIONROOT/processor/buildPackage.sh '$BUILDNUMBER' '$BRANCH' '$ACTION'"

if [ -z "$defaultBranch" ]; then
	defaultBranch='master'
else
	defaultBranch=$(eval "echo $defaultBranch")
fi

if [ "$BRANCH" == "$defaultBranch" ]; then
	echo; echo "[$scriptName] Only perform container test in CI for branches, $defaultBranch execution in CD pipeline"
else
	if [ -f "$SOLUTIONROOT/feature-branch.properties" ]; then
		echo "[$scriptName] Found $SOLUTIONROOT/feature-branch.properties, test for match with '$BRANCH' ..."; echo
		propList=$(eval "$AUTOMATIONROOT/remote/transform.sh $SOLUTIONROOT/feature-branch.properties")
		DEFAULT_IFS=$IFS
		IFS=$'\n'
		for featureProp in $propList; do
			IFS='='
			read -ra array <<< "$featureProp"
			featurePrefix=$(echo "${array[0]}" | tr '[:upper:]' '[:lower:]' | tr -d '[[:space:]]')
			branchLower=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]')
			featureEnv="${array[1]}"
			processEnv=$(eval "if [[ '$branchLower' == *'$featurePrefix'* ]]; then echo $featureEnv; fi")
			if [ ! -z "$processEnv" ]; then
				echo "  Deploy feature branch prefix '$featurePrefix'"
				featureBranchProcess='yes'
				if [ -z "$artifactPrefix" ]; then
					executeExpression "  ./TasksLocal/delivery.sh $processEnv"
				else
					executeExpression "  ./release.sh $processEnv"
				fi
			else
				echo "  Skip feature branch prefix '$featurePrefix' ($featureEnv)"
			fi
		done
		IFS=$DEFAULT_IFS
		if [ -z $featureBranchProcess ]; then
			echo
			if [ -z $defaultEnvironment ]; then
				echo "[$scriptName] No feature branches processed and defaultEnvironment not set, feature branch delivery not attempted."
			else
				echo "[$scriptName] Performing container test in CI for feature branch ($BRANCH), CD for default branch $defaultBranch"
				if [ -z "$artifactPrefix" ]; then
					executeExpression "./TasksLocal/delivery.sh $environment"
				else
					executeExpression "./release.sh $environment"
				fi
			fi
		fi
	else
		echo "[$scriptName] $SOLUTIONROOT/feature-branch.properties not found, performing container test in CI for feature branch ($BRANCH), CD for default branch $defaultBranch"
		if [ -z "$artifactPrefix" ]; then
			executeExpression "./TasksLocal/delivery.sh $environment"
		else
			executeExpression "./release.sh $environment"
		fi
	fi
fi

echo
if [ ! -z "$skipBranchCleanup" ]; then
	echo "[$scriptName] Branch not passed and using \$CDAF_BRANCH_NAME override, skipping clean-up ..."
else
	if [ -z "$gitRemoteURL" ]; then
		echo "[$scriptName] gitRemoteURL not defined in $SOLUTIONROOT/CDAF.solution, skipping clean-up ..."
	else
		if [[ $gitRemoteURL == *'$'* ]]; then
			gitRemoteURL=$(eval echo $gitRemoteURL)
		fi

		if [ -z "$gitRemoteURL" ]; then
			echo "[$scriptName] gitRemoteURL defined in $SOLUTIONROOT/CDAF.solution but not unresolved, skipping clean-up ..."
		else
			echo "[$scriptName] gitRemoteURL = ${gitRemoteURL}, perform branch cleanup ..."
			if [ -z "$gitUserNameEnvVar" ]; then
				echo "[$scriptName]   gitRemoteURL defined, but gitUserNameEnvVar not defined, relying on current workspace being up to date"
			else
				userName=$(eval "echo $gitUserNameEnvVar")
				if [ -z "$userName" ]; then
					echo "[$scriptName]   $gitUserNameEnvVar contains no value, relying on current workspace being up to date"
				else
					userName=${userName//@/%40}
					if [ -z "$gitUserPassEnvVar" ]; then
						ERRMSG "[GIT_CLEANUP]   gitUserNameEnvVar defined, but gitUserPassEnvVar not defined in $SOLUTIONROOT/CDAF.solution!" 6921
					fi
					userPass=$(eval "echo $gitUserPassEnvVar")
					if [ -z "$userPass" ]; then
						echo "[$scriptName]   $gitUserPassEnvVar contains no value, relying on current workspace being up to date"
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
						tempDir="${TEMP}/.cdaf-cache"
					else
						tempDir="${HOME}/.cdaf-cache"
					fi
					echo "[$scriptName] Workspace is not a Git repository or has detached head, skip branch clean-up and perform custom clean-up tasks in $tempDir ..."; echo
					executeExpression "mkdir -p $tempDir"
					executeExpression "cd $tempDir"
					repoName=${gitRemoteURL%/} # remove trailing /
					repoName=${repoName##*/}   # retrieve basename
					repoName=${repoName%.*}    # remove extension
					if [ ! -d "$repoName" ]; then
						executeExpression "git clone '${gitRemoteURL}'"
					fi
					executeExpression "cd $repoName"
					executeExpression "git fetch --prune '${gitRemoteURL}'"
					usingCache=$(git log -n 1 --pretty=%d HEAD 2> /dev/null)
					if [ $? -ne 0 ]; then echo "[$scriptName] Git cache update failed!"; exit 6924; fi
					echo "$usingCache"
					echo "git branch '${BRANCH}' 2> /dev/null"
					git branch "${BRANCH}" 2> /dev/null
					git checkout -b "${BRANCH}" 2> /dev/null # cater for ambiguous origin
					executeExpression "git checkout '${BRANCH}' 2> /dev/null"
					gitName=$(git config --list | grep user.name=)
					if [ -z "$gitName" ]; then
						git config user.name "Your Name"
					fi
					gitEmail=$(git config --list | grep user.email=)
					if [ -z "$gitEmail" ]; then
						git config user.email "you@example.com"
					fi
					executeExpression "git pull '${gitRemoteURL}'"
					echo; echo "[$scriptName] Load Remote branches using cache (git ls-remote --heads ${gitRemoteURL})"; echo
					lsRemote=$(git ls-remote --heads "${gitRemoteURL}")
				fi

			else

				echo; echo "$headAttached"; echo
				echo "[$scriptName] Refresh Remote branches"; echo
				if [ -z $userName ]; then
					executeExpression "git fetch --prune"
					echo; echo "[$scriptName] Load Remote branches (git ls-remote --heads origin)"; echo
					lsRemote=$(git ls-remote --heads origin)
				else
					executeExpression "git fetch --prune '${gitRemoteURL}'"
					echo; echo "[$scriptName] Load Remote branches (git ls-remote --heads ${gitRemoteURL})"; echo
					lsRemote=$(git ls-remote --heads "${gitRemoteURL}")
				fi

			fi

			if [ -z "$skipRemoteBranchCheck" ]; then
				for remoteBranch in $lsRemote; do 
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

				if [ ! -z "${usingCache}" ]; then
					executeExpression "cd $workspace"
				fi

				if [ ! -z "${headAttached}" ]; then
					echo; echo "[$scriptName] Process Local branches (git branch --format='%(refname:short)')"; echo
					for localBranch in $(git branch --format='%(refname:short)'); do
						branchName=${localBranch##*/}  # retrieve basename for compare
						if [[ " ${remoteArray[@]} " =~ " ${branchName} " ]]; then
							echo "  keep branch ${localBranch}"
						else
							executeSuppress "  git branch -D '${localBranch}'"
						fi
					done
				fi

				echo
				if [ -z ${gitCustomCleanup} ]; then
					echo "[$scriptName] gitCustomCleanup not defined in $SOLUTIONROOT/CDAF.solution, skipping ..."
				else
					argList="'${SOLUTION}'"
					for remoteBranch in "${remoteArray[@]}"; do
						argList="${argList} '${remoteBranch}'"
					done
					executeExpression "$gitCustomCleanup ${argList}"
				fi
			fi
		fi
	fi
fi

echo; echo "[$scriptName] ---------- stop ----------"
exit 0
