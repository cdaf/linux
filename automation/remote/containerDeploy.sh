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
TARGET=$1
if [ -z "$TARGET" ]; then
	echo "$scriptName TARGET Argument not passed. HALT!"
	exit 1341
else
	echo "[$scriptName]   TARGET      : $TARGET"
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

id=$5
if [ -z "$id" ]; then
	echo "$scriptName id Number not passed. HALT!"
	exit 1345
else
	echo "[$scriptName]   id          : $id"
fi

imageDir=$6
if [ -z "$imageDir" ]; then
	imageDir='containerDeploy'
	echo "[$scriptName]   imageDir    : $imageDir (not supplied, default set)"
else
	echo "[$scriptName]   imageDir    : $imageDir"
fi

WORKING_DIRECTORY=$(pwd)
echo "[$scriptName]   pwd         : $WORKING_DIRECTORY"

if [ ! -d "$imageDir" ]; then
	echo "[$scriptName] $imageDir does not exist! Please ensure this is included in your storeFor or stoteForLocal declaration file"
	exit 1346
fi

if [ -d "automation" ]; then
	executeExpression "cp -r 'automation' '$imageDir'"
fi

executeExpression "cp -r propertiesForContainerTasks $imageDir/properties"
if [ -f ../${SOLUTION}-${BUILDNUMBER}.tar.gz ]; then
	executeExpression "cp ../${SOLUTION}-${BUILDNUMBER}.tar.gz $imageDir/deploy.tar.gz"
else
	echo "[$scriptName][INFO] ..\${SOLUTION}-${BUILDNUMBER}.tar.gz not found."
fi
executeExpression "cd $imageDir"

echo;echo "[$scriptName] Remove any remaining deploy containers from previous (failed) deployments"
id=$(echo "${id}" | tr '[:upper:]' '[:lower:]') # docker image names must be lowercase

executeExpression "${WORKING_DIRECTORY}/dockerRun.sh ${id}"
export CDAF_CD_ENVIRONMENT=$TARGET
executeExpression "${WORKING_DIRECTORY}/dockerBuild.sh ${id} ${BUILDNUMBER} ${BUILDNUMBER} no $(whoami) $(id -u)"
executeExpression "${WORKING_DIRECTORY}/dockerClean.sh ${id} ${BUILDNUMBER}"

for envVar in $(env | grep CDAF_CD_); do
	envVar=$(echo ${envVar//CDAF_CD_})
	buildCommand+=" --env ${envVar}"
done

prefix=$(echo "${SOLUTION//-/_}" | tr '[:lower:]' '[:upper:]') # Environment Variables are uppercase by convention
for envVar in $(env | grep "CDAF_${prefix}_CD_"); do
	envVar=$(echo ${envVar//CDAF_${prefix}_CD_})
	buildCommand+=" --env ${envVar}"
done

# If a build number is not passed, use the CDAF emulator
executeExpression "export MSYS_NO_PATHCONV=1"
if [ -z "$HOME" ] || [[ $CDAF_HOME_MOUNT == 'no' ]]; then
	echo "[$scriptName] \$CDAF_HOME_MOUNT = $CDAF_HOME_MOUNT"
	echo "[$scriptName] \$HOME            = $HOME"
	executeExpression "docker run --tty ${buildCommand} --label cdaf.${id}.container.instance=${BUILDNUMBER} --name ${id} ${id}:${BUILDNUMBER} ./deploy.sh ${TARGET}"
else
	executeExpression "docker run --tty --user $(id -u) --volume ${HOME}:/solution/home ${buildCommand} --label cdaf.${id}.container.instance=${BUILDNUMBER} --name ${id} ${id}:${BUILDNUMBER} ./deploy.sh ${TARGET}"
fi

echo
executeExpression "${WORKING_DIRECTORY}/dockerRun.sh ${id}"

echo; echo "[$scriptName] --- end ---"
