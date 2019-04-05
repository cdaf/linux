#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$scriptName : Exception! $EXECUTABLESCRIPT returned $exitCode"
		if [ -f "Dockerfile.source" ]; then
			mv -f Dockerfile.source Dockerfile
		fi
		exit $exitCode
	fi
}  

scriptName=${0##*/}

echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not supplied, exit with code 1."
	exit 1
else
	echo "[$scriptName] imageName     : $imageName"
fi

BUILDNUMBER=$2
if [ -z "$BUILDNUMBER" ]; then
	echo "[$scriptName] BUILDNUMBER not supplied, exit with code 2."
	exit 2
else
	echo "[$scriptName] BUILDNUMBER   : $BUILDNUMBER"
fi

REVISION=$3
if [ -z "$REVISION" ]; then
	REVISION='container_build'
	echo "[$scriptName] REVISION      : $REVISION (not supplied, set to default)"
else
	echo "[$scriptName] REVISION      : $REVISION"
fi

ACTION=$4
if [ -z "$ACTION" ]; then
	echo "[$scriptName] ACTION        : (not supplied)"
else
	echo "[$scriptName] ACTION        : $ACTION"
fi

rebuildImage=$5
if [ -z "$rebuildImage" ]; then
	rebuildImage='no'
	echo "[$scriptName] rebuildImage  : $rebuildImage (not supplied, set to default)"
else
	echo "[$scriptName] rebuildImage  : $rebuildImage"
fi

# backward compatibility
cdafVersion=$6
if [ -z "$cdafVersion" ]; then
	echo "[$scriptName] cdafVersion   : (not supplied, pass dockerfile if your version of docker does not support label argument)"
else
	echo "[$scriptName] cdafVersion   : $cdafVersion"
fi

SOLUTIONROOT="$AUTOMATIONROOT/solution"
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
		SOLUTIONROOT="$directoryName"
	fi
done
echo "[$scriptName] SOLUTIONROOT  : $SOLUTIONROOT"
buildImage="${imageName}_$(echo "$REVISION" | awk '{print tolower($0)}')"
echo "[$scriptName] buildImage    : $buildImage"
echo "[$scriptName] DOCKER_HOST   : $DOCKER_HOST"
echo "[$scriptName] pwd           : $(pwd)"
echo "[$scriptName] hostname      : $(hostname)"
echo "[$scriptName] whoami        : $(whoami)"

# Test Docker is running
echo "[$scriptName] List all current images"
executeExpression "docker images"

buildCommand='docker build'
if [ "$rebuild" == 'yes' ]; then
	buildCommand+=" --no-cache=true"
fi

if [ -n "$tag" ]; then
	buildCommand+=" --tag ${buildImage}:${tag}"
else
	buildCommand+=" --tag ${buildImage}"
fi

imageTag=0
for tag in $(docker images --filter label=cdaf.${buildImage}.image.version --format "{{.Tag}}"); do
	if [ "${tag}" != '<none>' ]; then
		intTag=$((${tag}))
		if [[ $imageTag -le $intTag ]]; then
			imageTag=$intTag
		fi
	fi
done
echo "imageTag : $imageTag"
newTag=$((${imageTag} + 1))
echo "newTag   : $newTag"

executeExpression "cat Dockerfile"

if [ -z "$cdafVersion" ]; then
	cdafVersion=$newTag
else
	# CDAF Required Label
	executeExpression "cp -f Dockerfile Dockerfile.source"
	echo "LABEL	cdaf.dlan.image.version=\"$newTag\"" >> Dockerfile
fi
executeExpression "automation/remote/dockerBuild.sh ${buildImage} $newTag $cdafVersion $rebuildImage $(whoami) $(id -u)" 

if [ -f "Dockerfile.source" ]; then
	executeExpression "mv -f Dockerfile.source Dockerfile"
fi

# Remove any older images	
executeExpression "automation/remote/dockerClean.sh ${buildImage} $newTag"

workspace=$(pwd)
echo "[$scriptName] \$newTag    : $newTag"
echo "[$scriptName] \$workspace : $workspace"

test="`sestatus 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] sestatus   : (not installed)"
else
	test="`sestatus | grep 'SELinux status' 2>&1`"
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[2]}
	echo "[$scriptName] sestatus   : $test"
fi	

# If a build number is not passed, use the CDAF emulator
executeExpression "export MSYS_NO_PATHCONV=1"
executeExpression "docker run --tty --user $(id -u) --volume ${workspace}:/solution/workspace ${buildImage}:${newTag} ./automation/processor/buildPackage.sh $BUILDNUMBER $REVISION $ACTION"

echo "[$scriptName] List and remove all stopped containers"
executeExpression 'docker ps --filter "status=exited" -a'
executeExpression 'docker rm $(docker ps --filter "status=exited" -aq)'

echo
echo "[$scriptName] --- end ---"
