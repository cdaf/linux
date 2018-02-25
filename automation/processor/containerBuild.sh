#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		if [ -f "Dockerfile.source" ]; then
			mv -f Dockerfile.source Dockerfile
		fi
		exit $exitCode
	fi
}  

scriptName='containerBuild.sh'
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not supplied, exit with code 1."
	exit 1
else
	echo "[$scriptName] imageName     : $imageName"
fi

buildNumber=$2
if [ -z "$buildNumber" ]; then
	echo "[$scriptName] buildNumber   : (not supplied)"
else
	echo "[$scriptName] buildNumber   : $buildNumber"
fi

rebuildImage=$3
if [ -z "$rebuildImage" ]; then
	echo "[$scriptName] rebuildImage  : (not supplied)"
else
	echo "[$scriptName] rebuildImage  : $rebuildImage"
fi

# backward compatibility
cdafVersion=$4
if [ -z "$cdafVersion" ]; then
	echo "[$scriptName] cdafVersion   : (not supplied, pass dockerfile if your version of docker does not support label argument)"
else
	echo "[$scriptName] cdafVersion   : $cdafVersion"
fi

echo "[$scriptName] \$DOCKER_HOST  : $DOCKER_HOST"
SOLUTIONROOT="$AUTOMATIONROOT/solution"
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
		SOLUTIONROOT="$directoryName"
	fi
done
echo "[$scriptName] \$SOLUTIONROOT : $SOLUTIONROOT"
buildImage="${imageName}_container_build"
echo "[$scriptName] buildImage    : $buildImage"
echo "[$scriptName] whoami        : $(whoami)"
echo "[$scriptName] pwd           : $(pwd)"
echo "[$scriptName] hostname      : $(hostname)"

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
	intTag=$((${tag}))
	if [[ $imageTag -le $intTag ]]; then
		imageTag=$intTag
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
executeExpression "automation/remote/dockerBuild.sh ${buildImage} $newTag $cdafVersion $rebuildImage"

if [ -f "Dockerfile.source" ]; then
	executeExpression "mv -f Dockerfile.source Dockerfile"
fi

# Remove any older images	
executeExpression "automation/remote/dockerClean.sh ${buildImage} $newTag"

workspace=$(pwd)
echo "[$scriptName] \$newTag    : $newTag"
echo "[$scriptName] \$workspace : $workspace"

# If a build number is not passed, use the CDAF emulator
if [ -z "$buildNumber" ]; then
	executeExpression "docker run --tty --volume ${workspace}:/workspace ${buildImage}:${newTag}"
else
	executeExpression "docker run --tty --volume ${workspace}:/workspace ${buildImage}:${newTag} automation/remote/entrypoint.sh $buildNumber"
fi

echo "[$scriptName] List and remove all stopped containers"
executeExpression 'docker ps --filter "status=exited" -a'
executeExpression 'docker rm $(docker ps --filter "status=exited" -aq)'

if [ -f "$SOLUTIONROOT/imageBuild.sh" ]; then
	executeExpression "cd $SOLUTIONROOT"
	executeExpression "./imageBuild.sh"
	executeExpression "../automation/remote/dockerBuild.sh ${imageName} $buildNumber"
	executeExpression "./imageBuild.sh clean"
fi

echo
echo "[$scriptName] --- end ---"
