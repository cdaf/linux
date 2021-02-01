#!/usr/bin/env bash
scriptName='containerDeploy.sh'

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
	exit 1341
else
	echo "[$scriptName]   ENVIRONMENT : $ENVIRONMENT"
fi

if [ -z "$2" ]; then
	echo "$scriptName RELEASE Number not passed. HALT!"
	exit 1342
else
	RELEASE=$2
	echo "[$scriptName]   RELEASE     : $RELEASE"
fi

SOLUTION=$3
if [ -z "$SOLUTION" ]; then
	echo "[$scriptName] Solution Name not supplied. HALT!"
	exit 1343
else
	echo "[$scriptName]   SOLUTION    : $SOLUTION"
fi

BUILDNUMBER=$4
if [ -z "$BUILDNUMBER" ]; then
	echo "$scriptName Build Number not passed. HALT!"
	exit 1344
else
	echo "[$scriptName]   BUILDNUMBER : $BUILDNUMBER"
fi

REVISION=$5
if [ -z "$REVISION" ]; then
	echo "$scriptName REVISION Number not passed. HALT!"
	exit 1345
else
	echo "[$scriptName]   REVISION    : $REVISION"
fi

imageDir=$6
if [ -z "$imageDir" ]; then
	imageDir='containerDeploy'
	echo "[$scriptName]   imageDir    : $imageDir (not supplied, default set)"
else
	echo "[$scriptName]   imageDir    : $imageDir"
fi

if [ ! -d "$imageDir" ]; then
	echo "[$scriptName] $imageDir does not exist! Please ensure this is included in your storeFor or stoteForLocal declaration file"
	exit 1346
fi

if [ -d "automation" ]; then
	executeExpression "cp -r 'automation' '$imageDir'"
fi

executeExpression "cp -r propertiesForContainerTasks $imageDir/properties"
executeExpression "cp ../${SOLUTION}-${BUILDNUMBER}.tar.gz $imageDir/deploy.tar.gz"
executeExpression "cd $imageDir"

echo;echo "[$scriptName] Remove any remaining deploy containers from previous (failed) deployments"
id=$(echo "${SOLUTION}_${REVISION}_containerdeploy" | tr '[:upper:]' '[:lower:]') # docker image names must be lowercase

executeExpression "${CDAF_WORKSPACE}/dockerRun.sh ${id}"
export CDAF_CD_ENVIRONMENT=$ENVIRONMENT
executeExpression "${CDAF_WORKSPACE}/dockerBuild.sh ${id} ${BUILDNUMBER}"
executeExpression "${CDAF_WORKSPACE}/dockerClean.sh ${id} ${BUILDNUMBER}"

for envVar in $(env | grep CDAF_CD_); do
	buildCommand+=" --env ${envVar}"
done

prefix=$(echo "$SOLUTION" | tr '[:lower:]' '[:upper:]') # Environment Variables are uppercase by convention
echo "prefix = CDAF_${prefix}_CD_"
env | grep "CDAF_${prefix}_CD_"
for envVar in $(env | grep "CDAF_${prefix}_CD_"); do
	buildCommand+=" --env ${envVar}"
done

# If a build number is not passed, use the CDAF emulator
executeExpression "export MSYS_NO_PATHCONV=1"
if [ -z "$HOME" ]; then
	executeExpression "docker run --tty --user $(id -u) ${buildCommand} --label cdaf.${id}.container.instance=${REVISION} --name ${id} ${id}:${BUILDNUMBER} ./deploy.sh ${ENVIRONMENT}"
else
	executeExpression "docker run --tty --user $(id -u) --volume ${HOME}:/solution/home ${buildCommand} --label cdaf.${id}.container.instance=${REVISION} --name ${id} ${id}:${BUILDNUMBER} ./deploy.sh ${ENVIRONMENT}"
fi

echo
executeExpression "${CDAF_WORKSPACE}/dockerRun.sh ${id}"

echo; echo "[$scriptName] --- end ---"
