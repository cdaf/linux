#!/usr/bin/env bash
scriptName='containerTasks.sh'

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

echo
echo "[$scriptName] +-------------------------+"
echo "[$scriptName] | Process Container Tasks |"
echo "[$scriptName] +-------------------------+"
ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
	echo "$scriptName ENVIRONMENT Argument not passed. HALT!"
	exit 1331
else
	ENVIRONMENT=$1
	echo "[$scriptName]   ENVIRONMENT      : $ENVIRONMENT"
fi

RELEASE=$2
if [ -z "$RELEASE" ]; then
	echo "$scriptName RELEASE Argument not passed. HALT!"
	exit 1332
else
	echo "[$scriptName]   RELEASE      : $RELEASE"
fi

BUILDNUMBER=$3
if [ -z "$BUILDNUMBER" ]; then
	echo "$scriptName Build Number not passed. HALT!"
	exit 1333
else
	echo "[$scriptName]   BUILDNUMBER      : $BUILDNUMBER"
fi

SOLUTION=$4
if [ -z "$3" ]; then
	echo "[$scriptName] Solution Name not supplied. HALT!"
	exit 1334
else
	echo "[$scriptName]   SOLUTION         : $SOLUTION"
fi

landingDir=$(pwd)
WORK_DIR_DEFAULT=$5
if [ "$WORK_DIR_DEFAULT" ]; then
	echo "[$scriptName]   WORK_DIR_DEFAULT : $WORK_DIR_DEFAULT"
else
	WORK_DIR_DEFAULT=$landingDir
	echo "[$scriptName]   WORK_DIR_DEFAULT : $WORK_DIR_DEFAULT (not passed, using landing directory)"
fi

OPT_ARG=$6
if [ -z "$OPT_ARG" ]; then
	echo "[$scriptName]   OPT_ARG          : (Optional task argument not supplied)"
else
	echo "[$scriptName]   OPT_ARG          : $OPT_ARG"
fi

echo "[$scriptName]   whoami           : $(whoami)"
echo "[$scriptName]   hostname         : $(hostname)"
echo "[$scriptName]   pwd              : $landingDir"

if [ -d "$WORK_DIR_DEFAULT/propertiesForContainerTasks" ]; then

	# 2.4.0 The containerDeploy is an extension to remote tasks, which means recursive call to this script should not happen (unlike containerBuild)
	# containerDeploy example ${CDAF_WORKSPACE}/containerDeploy.sh "${ENVIRONMENT}" "${RELEASE}" "${SOLUTION}" "${BUILDNUMBER}" "${REVISION}"
	containerDeploy=$($WORK_DIR_DEFAULT/getProperty.sh "$WORK_DIR_DEFAULT/manifest.txt" "containerDeploy")
	REVISION=$($WORK_DIR_DEFAULT/getProperty.sh "$WORK_DIR_DEFAULT/manifest.txt" "REVISION")
	if [ ! -z "$containerDeploy" ]; then
		test=$(docker --version 2>&1)
		if [ $? -ne 0 ]; then
			echo "[$scriptName]   Docker           : containerDeploy defined in $SOLUTIONROOT/CDAF.solution, but Docker not installed, will attempt to execute natively"
			unset containerDeploy
		else
			IFS=' ' read -ra ADDR <<< $test
			IFS=',' read -ra ADDR <<< ${ADDR[2]}
			dockerRun="${ADDR[0]}"
			echo "[$scriptName]   Docker           : $dockerRun"
			# Test Docker is running
			echo "[$scriptName] List all current images"
			echo "docker images"
			docker images
			if [ "$?" != "0" ]; then
				if [ -z $CDAF_DOCKER_REQUIRED ]; then
					echo "[$scriptName] Docker installed but not running, will attempt to execute natively (set CDAF_DOCKER_REQUIRED if docker is mandatory)"
					unset containerDeploy
				else
					echo "[$scriptName] Docker installed but not running, CDAF_DOCKER_REQUIRED is set so will try and start"
					if [ $(whoami) != 'root' ];then
						elevate='sudo'
					fi
					executeExpression "$elevate service docker start"
					executeExpression "$elevate service docker status"
				fi
			fi
		fi
		echo
		if [ -z "$containerDeploy" ]; then
			if [ -d "$WORK_DIR_DEFAULT/propertiesForLocalTasks/$ENVIRONMENT*" ]; then
				echo "[$scriptName]   Cannot use container properties for local execution as existing local definition exits"
			else
				if [ ! -d "$WORK_DIR_DEFAULT/propertiesForLocalTasks" ]; then
					executeExpression "mkdir -p $WORK_DIR_DEFAULT/propertiesForLocalTasks"
				fi
				executeExpression "cp -v $WORK_DIR_DEFAULT/propertiesForContainerTasks/$ENVIRONMENT* $WORK_DIR_DEFAULT/propertiesForLocalTasks"
				executeExpression "cp -v $WORK_DIR_DEFAULT/propertiesForContainerTasks/$ENVIRONMENT* $WORK_DIR_DEFAULT"
				echo
				executeExpression "$WORK_DIR_DEFAULT/localTasks.sh '$ENVIRONMENT' '$BUILDNUMBER' '$SOLUTION' '$WORK_DIR_DEFAULT' '$OPT_ARG'"
			fi
		else
			export CONTAINER_IMAGE=$($WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/manifest.txt" "containerImage")
			export CDAF_WORKSPACE="$(pwd)/${WORK_DIR_DEFAULT}"
			executeExpression "cd '${CDAF_WORKSPACE}'"
			echo
			executeExpression "$containerDeploy"
			executeExpression "cd '$landingDir'"
		fi
	else
		echo "[$scriptName]   containerDeploy  : (not defined in $SOLUTIONROOT/CDAF.solution)"
	fi
else
	echo; echo "[$scriptName]   Properties directory ($workingDir/propertiesForContainerTasks) not found, no action taken."
fi