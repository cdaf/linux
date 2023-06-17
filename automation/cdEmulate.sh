#!/usr/bin/env bash

# Emulate calling the package and deploy process as it would be from the automation toolset, e.g. Bamboo or Jenkings. 
# Workspace with temp space. The variables provided in Jenkins are emulated in the scripts themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
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
	if [ ! -z "$CDAF_ERROR_DIAG" ]; then
		echo; echo "[$scriptName] Invoke custom diag CDAF_ERROR_DIAG = $CDAF_ERROR_DIAG"; echo
		eval "$CDAF_ERROR_DIAG"
	fi
	if [ ! -z "$2" ]; then
		echo; echo "[$scriptName] Exit with LASTEXITCODE = $2" ; echo
		exit $2
	fi
}

# Check Action
ACTION="$1"

scriptName=${0##*/}

# Reload any environment variables
if [ -f "/etc/bash.bashrc" ]; then
	source /etc/bash.bashrc
fi
if [ -f "~/.bashrc" ]; then
	source ~/.bashrc
fi

echo; echo "[$scriptName] --------------------"
echo "[$scriptName] Initialise Emulation"
echo "[$scriptName] --------------------"
if [ -z "${CDAF_BRANCH_NAME}" ]; then
	echo "[$scriptName]   ACTION         : (not supplied, options cionly, buildonly, packageonly or cdonly)"
else
	echo "[$scriptName]   ACTION         : $ACTION"
	caseinsensitive=$(echo "$ACTION" | tr '[A-Z]' '[a-z]')
fi

# Use a simple text file (${HOME}/BUILDNUMBER.counter) for incremental build number
if [ -f "${HOME}/BUILDNUMBER.counter" ]; then
	let "BUILDNUMBER=$(cat ${HOME}/BUILDNUMBER.counter|tr -d '\r')" # in case the home directory is shared by Windows and Linux
else
	let "BUILDNUMBER=0"
fi
if [ "$caseinsensitive" != "cdonly" ]; then
	let "BUILDNUMBER=$BUILDNUMBER + 1"
fi
echo $BUILDNUMBER > ${HOME}/BUILDNUMBER.counter
echo "[$scriptName]   BUILDNUMBER    : $BUILDNUMBER"

if [ ! -z "${CDAF_BRANCH_NAME}" ]; then
	REVISION=${CDAF_BRANCH_NAME}
else
	REVISION="release"
fi
echo "[$scriptName]   REVISION       : $REVISION"

workDirLocal="TasksLocal"
workDirRemote="TasksRemote"

# Framework structure
AUTOMATIONROOT="$( cd "$(dirname "$0")" && pwd )"
echo "[$scriptName]   AUTOMATIONROOT : $AUTOMATIONROOT"
CDAF_CORE="${AUTOMATIONROOT}/remote"

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "[$scriptName]   SOLUTIONROOT   : "
for directoryName in $(find . -maxdepth 1 -mindepth 1 -type d); do
	if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
		SOLUTIONROOT="$directoryName"
	fi
done
if [ -z "$SOLUTIONROOT" ]; then
	ERRMSG "[NO_SOLUTION_ROOT] No directory found containing CDAF.solution, please create a single occurrence of this file." 7611
else
	echo "$SOLUTIONROOT (override $SOLUTIONROOT/CDAF.solution found)"
fi

SOLUTION=$("${CDAF_CORE}/getProperty.sh" "$SOLUTIONROOT/CDAF.solution" "solutionName")
exitCode=$?
if [ "$exitCode" != "0" ]; then
	ERRMSG "[SOLUTION_NOT_FOUND] Read of SOLUTION from $SOLUTIONROOT/CDAF.solution failed!" $exitCode
fi
if [ -z "$SOLUTION" ]; then
	ERRMSG "[SOLUTION_NAME_NOT_SET] solutionName not found in $SOLUTIONROOT/CDAF.solution!" 1030
fi
echo "[$scriptName]   SOLUTION       : $SOLUTION (from CDAF.solution)"

# If not set as an environment variablem, delivery properties Lookup values
if [ -z "${CDAF_DELIVERY}" ]; then
	if [ -f "$SOLUTIONROOT/deliveryEnv.sh" ]; then
		CDAF_DELIVERY=$($SOLUTIONROOT/deliveryEnv.sh)
		echo "[$scriptName]   CDAF_DELIVERY  : $CDAF_DELIVERY (using override $SOLUTIONROOT/deliveryEnv.sh)"
	else
		if [ ! $CDAF_DELIVERY ]; then
			CDAF_DELIVERY="LINUX"
		fi
		echo "[$scriptName]   CDAF_DELIVERY  : $CDAF_DELIVERY (override $SOLUTIONROOT/deliveryEnv.sh not found)"
	fi
fi

# Check for customised CI process
printf "[$scriptName]   ciProcess      : "
if [ -f "$SOLUTIONROOT/buildPackage.sh" ]; then
	cdProcess="$SOLUTIONROOT/buildPackage.sh"
	echo "$ciProcess (override)"
else
	ciProcess="$AUTOMATIONROOT/ci.sh"
	echo "$ciProcess (default)"
fi

# Check for customised Delivery process
printf "[$scriptName]   cdProcess      : "
if [ -f "$SOLUTIONROOT/delivery.sh" ]; then
	cdProcess="$SOLUTIONROOT/delivery.sh"
	echo "$cdProcess (override)"
else
	artifactPrefix=$("${CDAF_CORE}/getProperty.sh" "$SOLUTIONROOT/CDAF.solution" "artifactPrefix")
	if [ -z $artifactPrefix ]; then
		cdProcess="$workDirLocal/delivery.sh"
		echo "$cdProcess (default)"
	else
		cdProcess="./release.sh"
		echo "$cdProcess (due to artifactPrefix being set in $SOLUTIONROOT/CDAF.solution)"
	fi
fi

if [ "$caseinsensitive" != "cdonly" ]; then
	"$ciProcess" "$BUILDNUMBER" "$REVISION" "$ACTION"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		ERRMSG "[CI_FAILURE] CI Failed with exit code $exitCode! $ciProcess \"$BUILDNUMBER\" \"$REVISION\" \"$ACTION\"" $exitCode
	fi
fi

# Do not process Remote and Local Tasks if the action is cionly or clean
if [ "$caseinsensitive" != "cionly" ] && [ "$caseinsensitive" != "buildonly" ] && [ "$caseinsensitive" != "packageonly" ] && [ "$caseinsensitive" != "clean" ]; then

	# If running in VirtualBox on windows, bit changes can be delayed
	if [ ! -x $cdProcess ]; then
		sleep 1
	fi

	$cdProcess "$CDAF_DELIVERY"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		ERRMSG "[CD_FAILURE] CD Failed with exit code $exitCode! $cdProcess \"$CDAF_DELIVERY\"" $exitCode
	fi
fi

echo
echo "[$scriptName] ------------------"
echo "[$scriptName] Emulation Complete"
echo "[$scriptName] ------------------"
echo
