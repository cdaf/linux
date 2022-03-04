#!/usr/bin/env bash
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
# Emulate calling the package and deploy process as it would be from the automation toolset, e.g. Bamboo or Jenkings. 
# Workspace with temp space. The variables provided in Jenkins are emulated in the scripts themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

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
echo "[$scriptName]   ACTION         : $ACTION"
caseinsensitive=$(echo "$ACTION" | tr '[A-Z]' '[a-z]')

workDirLocal="TasksLocal"
workDirRemote="TasksRemote"

# Framework structure
automationRoot="$( cd "$(dirname "$0")" && pwd )"
echo "[$scriptName]   automationRoot : $automationRoot"
export CDAF_AUTOMATION_ROOT=$AUTOMATIONROOT

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

# If not set as an environment variablem, delivery properties Lookup values
if [ -z "${CDAF_DELIVERY}" ]; then
	if [ -f "$solutionRoot/deliveryEnv.sh" ]; then
		CDAF_DELIVERY=$($solutionRoot/deliveryEnv.sh)
		echo "[$scriptName]   CDAF_DELIVERY  : $CDAF_DELIVERY (using override $solutionRoot/deliveryEnv.sh)"
	else
		if [ ! $CDAF_DELIVERY ]; then
			CDAF_DELIVERY="LINUX"
		fi
		echo "[$scriptName]   CDAF_DELIVERY  : $CDAF_DELIVERY (override $solutionRoot/deliveryEnv.sh not found)"
	fi
fi

# Use a simple text file (${HOME}/buildnumber.counter) for incremental build number
if [ -f "${HOME}/buildnumber.counter" ]; then
	let "buildNumber=$(cat ${HOME}/buildnumber.counter|tr -d '\r')" # in case the home directory is shared by Windows and Linux
else
	let "buildNumber=0"
fi
if [ "$caseinsensitive" != "cdonly" ]; then
	let "buildNumber=$buildNumber + 1"
fi
echo $buildNumber > ${HOME}/buildnumber.counter

if [ ! -z "${CDAF_BRANCH_NAME}" ]; then
	revision=${CDAF_BRANCH_NAME}
else
	revision="release"
fi
echo "[$scriptName]   buildNumber    : $buildNumber"
echo "[$scriptName]   revision       : $revision"

# Check for customised CI process
printf "[$scriptName]   ciProcess      : "
if [ -f "$solutionRoot/buildPackage.sh" ]; then
	cdProcess="$solutionRoot/buildPackage.sh"
	echo "$ciProcess (override)"
else
	ciProcess="$automationRoot/processor/buildPackage.sh"
	echo "$ciProcess (default)"
fi

# Check for customised Delivery process
printf "[$scriptName]   cdProcess      : "
if [ -f "$solutionRoot/delivery.sh" ]; then
	cdProcess="$solutionRoot/delivery.sh"
	echo "$cdProcess (override)"
else
	artifactPrefix=$($automationRoot/remote/getProperty.sh "$solutionRoot/CDAF.solution" "artifactPrefix")
	if [ -z $artifactPrefix ]; then
		cdProcess="$workDirLocal/delivery.sh"
		echo "$cdProcess (default)"
	else
		cdProcess="./release.sh"
		echo "$cdProcess (due to artifactPrefix being set in $solutionRoot/CDAF.solution)"
	fi
fi

# If a solution properties file exists, load the properties
if [ -f "$solutionRoot/CDAF.solution" ]; then
	echo
	echo "[$scriptName] Load Solution Properties $solutionRoot/CDAF.solution"
	propertiesList=$($automationRoot/remote/transform.sh "$solutionRoot/CDAF.solution")
	echo "$propertiesList"
	eval $propertiesList
fi

# If the Solution is not defined in the CDAF.solution file, do not attempt to derive, instead, throw error.
if [ -z "$solutionName" ]; then
	echo; echo "[$scriptName] solutionName not defined in $solutionRoot/CDAF.solution, exiting with code 3"; exit 3
fi

if [ "$caseinsensitive" != "cdonly" ]; then
	$ciProcess "$buildNumber" "$revision" "$ACTION"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] CI Failed! $ciProcess \"$buildNumber\" \"$revision\" \"$ACTION\". Halt with exit code = $exitCode."
		exit $exitCode
	fi
fi

# Do not process Remote and Local Tasks if the action is cionly or clean
if [ "$caseinsensitive" != "cionly" ] && [ "$caseinsensitive" != "buildonly" ] && [ "$caseinsensitive" != "packageonly" ] && [ "$caseinsensitive" != "clean" ]; then
	$cdProcess "$CDAF_DELIVERY"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] CD Failed! $cdProcess \"$CDAF_DELIVERY\". Halt with exit code = $exitCode."
		exit $exitCode
	fi
fi

echo
echo "[$scriptName] ------------------"
echo "[$scriptName] Emulation Complete"
echo "[$scriptName] ------------------"
echo
