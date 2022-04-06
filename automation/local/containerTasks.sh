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

function getProp {
	propValue=$($WORK_DIR_DEFAULT/getProperty.sh "$1" "$2")
	echo $propValue
}

echo; echo "[$scriptName] +-------------------------+"
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
	echo "[$scriptName]   RELEASE          : $RELEASE"
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

WORK_DIR_DEFAULT=$5
echo "[$scriptName]   WORK_DIR_DEFAULT : $WORK_DIR_DEFAULT"

# Capture landing directory, then change to Default Working Directory and resolve to absolute path
CDAF_WORKSPACE=$(pwd)
cd $WORK_DIR_DEFAULT
WORK_DIR_DEFAULT=$(pwd)

OPT_ARG=$6
echo "[$scriptName]   OPT_ARG          : $OPT_ARG"

echo "[$scriptName]   CDAF Version     : $(getProp "CDAF.properties" "productVersion")"
echo "[$scriptName]   whoami           : $(whoami)"
echo "[$scriptName]   hostname         : $(hostname)"
echo "[$scriptName]   pwd              : $WORK_DIR_DEFAULT"

if [ -d "./propertiesForContainerTasks" ]; then

	propertiesFilter=$(find "${WORK_DIR_DEFAULT}/propertiesForContainerTasks/${ENVIRONMENT}"* | sort)
	if [ -z "$propertiesFilter" ]; then
		echo "[$scriptName][INFO] Properties directory ($propertiesFilter) not found, alter processSequence property to skip."
	else
		# Verify docker available
		test=$(docker --version 2>&1)
		if [ $? -ne 0 ]; then
			ERRMSG "[NO_DOCKER] Docker not installed or running" 3913
		else
			IFS=' ' read -ra ADDR <<< $test
			IFS=',' read -ra ADDR <<< ${ADDR[2]}
			dockerRun="${ADDR[0]}"
			echo "[$scriptName]   Docker           : $dockerRun"
		fi
	
		# Test Docker is running
		imageLIst=$(docker images)
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
	
		# 2.4.0 Introduce containerDeploy as a prescriptive "remote" process, changed in 2.5.0 to allow re-use of compose assets
		containerDeploy=$(getProp 'manifest.txt' 'containerDeploy')
		REVISION=$(getProp 'manifest.txt' 'REVISION')
	
		# 2.5.0 Provide default containerDeploy execution, replacing "remote" process with "local" process, but retaining containerRemote.ps1 to support 2.4.0 functionality
		if [ -z $containerDeploy ]; then
			containerDeploy='${WORK_DIR_DEFAULT}/containerDeploy.sh "${TARGET}" "${RELEASE}" "${SOLUTION}" "${BUILDNUMBER}" "${REVISION}"'
			echo "[$scriptName]   containerDeploy  : $containerDeploy (Default)"
		else
			echo "[$scriptName]   containerDeploy  : $containerDeploy"
		fi
	
		deployImage=$(getProp 'manifest.txt' 'deployImage')
		if [ ! -z $deployImage ]; then
			export CONTAINER_IMAGE=$deployImage
			echo "[$scriptName]   CONTAINER_IMAGE  : ${CONTAINER_IMAGE} (deployImage)"
		else
			runtimeImage=$(getProp 'manifest.txt' 'runtimeImage')
			if [ ! -z $runtimeImage ]; then
				export CONTAINER_IMAGE=$runtimeImage
				echo "[$scriptName]   CONTAINER_IMAGE  : ${CONTAINER_IMAGE} (runtimeImage)"
			else
				containerImage=$(getProp 'manifest.txt' 'containerImage')
				if [ ! -z $containerImage ]; then
					export CONTAINER_IMAGE=$containerImage
					echo "[$scriptName]   CONTAINER_IMAGE  : ${CONTAINER_IMAGE} (containerImage)"
				else
					ERRMSG "[DEPLOY_BASE_IMAGE_NOT_DEFINED] Base image not defined in either deployImage, runtimeImage nor containerImage in CDAF.solution" 3911
				fi
			fi
		fi
	
		echo; echo "[$scriptName] List all current images"
		echo "$imageLIst"; echo
	
		# 2.5.0 Process all containerDeploy environments based on prefix pattern (align with localTasks and remoteTasks)
		echo; echo "[$scriptName] Preparing to process deploy targets :"
		for propFile in $propertiesFilter; do
			echo "[$scriptName]   $(basename "$propFile")"
		done
		echo
	
		for propFile in $propertiesFilter; do
			TARGET=$(basename "$propFile")
			echo "[$scriptName] Processing \$TARGET = $TARGET..."; echo
			executeExpression "$containerDeploy"
			executeExpression "cd '$WORK_DIR_DEFAULT'" # Return to Landing Directory in case a custom containerTask has been used, e.g. containerRemote
		done
	fi
else
	echo
	echo "[$scriptName]   Properties directory (./propertiesForContainerTasks) not found, no action taken."
fi
