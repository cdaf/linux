#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		step=${1%% *}
		filename=$(basename $step)
		echo "[$scriptName][CDAF_DELIVERY_FAILURE.${filename%.*}] Execute FAILURE Returned $exitCode"
		exit $exitCode
	fi
}

# Entry point for Delivery automation.

scriptName=${0##*/}

echo
echo "[$scriptName] ================================="
echo "[$scriptName] Continuous Delivery (CD) Starting"
echo "[$scriptName] ================================="

unset CDAF_AUTOMATION_ROOT

ENVIRONMENT="$1"
if [[ $ENVIRONMENT == *'$'* ]]; then
	ENVIRONMENT=$(eval echo $ENVIRONMENT)
fi
if [ -z "$ENVIRONMENT" ]; then
	echo "[$scriptName] Environment required! EXiting code 1"; exit 1
fi 
echo "[$scriptName]   ENVIRONMENT      : $ENVIRONMENT"

RELEASE="$2"
if [[ $RELEASE == *'$'* ]]; then
	RELEASE=$(eval echo $RELEASE)
fi
if [ -z "$RELEASE" ]; then
	RELEASE='Release'
	echo "[$scriptName]   RELEASE          : $RELEASE (default)"
else
	echo "[$scriptName]   RELEASE          : $RELEASE"
fi 

OPT_ARG="$3"
echo "[$scriptName]   OPT_ARG          : $OPT_ARG"

WORK_DIR_DEFAULT="$4"
if [ -z "$WORK_DIR_DEFAULT" ]; then
	WORK_DIR_DEFAULT='TasksLocal'
fi 
echo "[$scriptName]   WORK_DIR_DEFAULT : $WORK_DIR_DEFAULT"
export CDAF_CORE="$(pwd)/${WORK_DIR_DEFAULT}"
echo "[$scriptName]   CDAF_CORE        : $CDAF_CORE"

SOLUTION="$5"
if [[ $SOLUTION == *'$'* ]]; then
	SOLUTION=$(eval echo $SOLUTION)
fi
if [ -z "$SOLUTION" ]; then
	SOLUTION=$(${CDAF_CORE}/getProperty.sh "${CDAF_CORE}/manifest.txt" "SOLUTION")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Read of SOLUTION from ${CDAF_CORE}/manifest.txt failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "[$scriptName]   SOLUTION         : $SOLUTION (derived from $WORK_DIR_DEFAULT/manifest.txt)"
else
	echo "[$scriptName]   SOLUTION         : $SOLUTION"
fi 

BUILDNUMBER="$6"
if [[ $BUILDNUMBER == *'$'* ]]; then
	BUILDNUMBER=$(eval echo $BUILDNUMBER)
fi
if [ -z "$BUILDNUMBER" ]; then
	BUILDNUMBER=$(${CDAF_CORE}/getProperty.sh "${CDAF_CORE}/manifest.txt" "BUILDNUMBER")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Read of BUILDNUMBER from ${CDAF_CORE}/manifest.txt failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "[$scriptName]   BUILDNUMBER      : $BUILDNUMBER (derived from $WORK_DIR_DEFAULT/manifest.txt)"
else
	echo "[$scriptName]   BUILDNUMBER      : $BUILDNUMBER"
fi 

# Load TargetlessCD environment variable
export WORK_SPACE=$(pwd)
export WORKSPACE="${WORK_SPACE}\${WORK_DIR_DEFAULT}"
echo "[$scriptName]   pwd              : ${WORK_SPACE}"
echo "[$scriptName]   whoami           : $(whoami)"
echo "[$scriptName]   hostname         : $(hostname)"
echo "[$scriptName]   CDAF Version     : $(${CDAF_CORE}/getProperty.sh "${CDAF_CORE}/CDAF.properties" "productVersion")"

# 2.5.5 default error diagnostic command as solution property
if [ -z "$CDAF_ERROR_DIAG" ]; then
	export CDAF_ERROR_DIAG=$(${CDAF_CORE}/getProperty.sh "${CDAF_CORE}/manifest.txt" "CDAF_ERROR_DIAG")
	if [ -z "$CDAF_ERROR_DIAG" ]; then
		echo "[$scriptName]   CDAF_ERROR_DIAG  : (not set or defined in ${CDAF_CORE}/manifest.txt)"
	else
		echo "[$scriptName]   CDAF_ERROR_DIAG  : $CDAF_ERROR_DIAG (defined in ${CDAF_CORE}/manifest.txt)"
	fi
else
	echo "[$scriptName]   CDAF_ERROR_DIAG  : $CDAF_ERROR_DIAG"
fi

processSequence=$(${CDAF_CORE}/getProperty.sh "${CDAF_CORE}/manifest.txt" "processSequence")
if [ -z "$processSequence" ]; then
	processSequence='remoteTasks.sh localTasks.sh containerTasks.sh'
else
	echo "[$scriptName]   processSequence  : $processSequence (override)"
fi

for step in $processSequence; do
	echo
	executeExpression "${CDAF_CORE}/${step} '$ENVIRONMENT' '$RELEASE' '$BUILDNUMBER' '$SOLUTION' '$WORK_DIR_DEFAULT' '$OPT_ARG'"
done


echo; echo "[$scriptName] ========================================="
echo "[$scriptName]        Delivery Process Complete"
echo "[$scriptName] ========================================="
