#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName=${0##*/}

echo "[$scriptName] --- start ---"
imageName="$1"
if [ ! -z "$imageName" ]; then
	echo "[$scriptName]   imageName            : $imageName"

	BUILDNUMBER="$2"
	if [ -z "$BUILDNUMBER" ]; then
		echo "[$scriptName]   BUILDNUMBER not supplied, exit with code 2."
		exit 2
	else
		echo "[$scriptName]   BUILDNUMBER          : $BUILDNUMBER"
	fi
	
	REVISION="$3"
	if [ -z "$REVISION" ]; then
		REVISION='container_build'
		echo "[$scriptName]   REVISION             : $REVISION (not supplied, set to default)"
	else
		echo "[$scriptName]   REVISION             : $REVISION"
	fi
	
	ACTION="$4"
	if [ -z "$ACTION" ]; then
		echo "[$scriptName]   ACTION               : (not supplied)"
	else
		echo "[$scriptName]   ACTION               : $ACTION"
	fi
	
	rebuildImage="$5"
	if [ -z "$rebuildImage" ]; then
		rebuildImage='no'
		echo "[$scriptName]   rebuildImage         : $rebuildImage (not supplied, set to default)"
	else
		echo "[$scriptName]   rebuildImage         : $rebuildImage"
	fi

	if [ ! -z "$CDAF_DOCKER_RUN_ARGS" ]; then
		echo "[$scriptName]   CDAF_DOCKER_RUN_ARGS : $CDAF_DOCKER_RUN_ARGS"
	fi
else
	echo "[$scriptName]   imageName           : (not supplied, only process CDAF automation load)"
fi

absolute=$(echo "$(pwd)/automation")
if [ -d "$absolute" ]; then
	if [[ "$AUTOMATIONROOT" != "$absolute" ]]; then
		echo "[$scriptName]   AUTOMATIONROOT       : ${AUTOMATIONROOT} (copy to ./automation in workspace for docker)"
		cleanupCDAF='yes'
	else
		echo "[$scriptName]   AUTOMATIONROOT       : ${AUTOMATIONROOT}"
	fi
else
	if [[ $AUTOMATIONROOT != $absolute ]]; then
		echo "[$scriptName]   AUTOMATIONROOT       : ${AUTOMATIONROOT} (copy to ./automation in workspace for docker)"
		cleanupCDAF='yes'
	else
		echo "[$scriptName]   AUTOMATIONROOT       : ${AUTOMATIONROOT}"
	fi
fi

if [ ! -z "$imageName" ]; then
	for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
		directoryName=${i%%/}
		if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
			SOLUTIONROOT="$directoryName"
		fi
	done
	if [ -z "$SOLUTIONROOT" ]; then
		SOLUTIONROOT="${AUTOMATIONROOT}/solution"
		echo "[$scriptName]   SOLUTIONROOT         : $SOLUTIONROOT (CDAF.solution not found, so using default)"
	else
		echo "[$scriptName]   SOLUTIONROOT         : $SOLUTIONROOT"
	fi

	SOLUTION=$("$AUTOMATIONROOT/remote/getProperty.sh" "$SOLUTIONROOT/CDAF.solution" "solutionName")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Read of SOLUTION from $SOLUTIONROOT/CDAF.solution failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "[$scriptName]   SOLUTION             : $SOLUTION (derived from $SOLUTIONROOT/CDAF.solution)"

	buildImage="${imageName}_$(echo "$REVISION" | awk '{print tolower($0)}')_containerbuild"
	echo "[$scriptName]   buildImage           : $buildImage"

	echo "[$scriptName]   DOCKER_HOST          : $DOCKER_HOST"
	echo "[$scriptName]   pwd                  : $(pwd)"
	echo "[$scriptName]   hostname             : $(hostname)"
	echo "[$scriptName]   whoami               : $(whoami)"

	echo; echo "[$scriptName] Prepare image..."

	if [ "$cleanupCDAF" == 'yes' ]; then
		executeExpression "    rm -rf ./automation"
		executeExpression "    cp -a '$AUTOMATIONROOT' ./automation"
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
	echo "[$scriptName]    imageTag       : $imageTag"
	newTag=$((${imageTag} + 1))
	echo "[$scriptName]    newTag         : $newTag"

	# 2.6.1 Default Dockerfile for containerBuild
	if [ ! -f './Dockerfile' ]; then
		dockerfile_name='Dockerfile-cb-temp'

# Cannot indent heredoc
(
cat <<-EOF
# DOCKER-VERSION 1.2.0
ARG CONTAINER_IMAGE
FROM \${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Prepare for non-root build
ARG userName
ARG userID

RUN user=\$(id -nu \$userID 2>/dev/null || exit 0) ; \\
	if [ ! -z "\$user" ]; then \\
		userdel -f \$user ; \\
	fi ;  \\
	adduser \$userName --uid \$userID --disabled-password --gecos "" ; \\
	chown \$userName -R /solution

USER \$userName

# Move to subdirectory for build, i.e. /solution/workspace
WORKDIR /solution/workspace

CMD ["sleep", "infinity"]

EOF
) | tee $dockerfile_name

	fi	
	
	executeExpression "'$CDAF_CORE/dockerBuild.sh' ${buildImage} $newTag $rebuildImage $(whoami) $(id -u)" 
	
	# Remove any older images	
	executeExpression "'$CDAF_CORE/dockerClean.sh' ${buildImage} $newTag"
	
	workspace=$(pwd)
	echo "[$scriptName] \$newTag          : $newTag"
	echo "[$scriptName] \$workspace       : $workspace"
	
	test="`sestatus 2>&1`"
	if [[ "$test" == *"not found"* ]]; then
		echo "[$scriptName] sestatus         : (not installed)"
	else
		test="`sestatus | grep 'SELinux status' 2>&1`"
		IFS=' ' read -ra ADDR <<< $test
		test=${ADDR[2]}
		echo "[$scriptName] sestatus         : $test"
	fi	

	if [ ! -z "$CDAF_BUILD_ENV" ]; then
		buildCommand+=" --env 'CDAF_BUILD_ENV=$CDAF_BUILD_ENV'"
	fi

	for envVar in $(env | grep CDAF_CB_); do
		envVar=$(echo ${envVar//CDAF_CB_})
		buildCommand+=" --env '${envVar}'"
	done

	prefix=$(echo "$SOLUTION" | tr '[:lower:]' '[:upper:]') # Environment Variables are uppercase by convention
	echo "prefix = CDAF_${prefix}_CB_"
	env | grep "CDAF_${prefix}_CB_"
	for envVar in $(env | grep "CDAF_${prefix}_CB_"); do
		envVar=$(echo ${envVar//CDAF_${prefix}_CB_})
		buildCommand+=" $CDAF_DOCKER_RUN_ARGS --env '${envVar}'"
	done

	# :Z flag sets Podman to label the volume content as "private unshared" with SELinux. This label allows the container to write to the volume. https://www.tutorialworks.com/podman-rootless-volumes/
	# Because podman is rootless, the resulting output is still owned by the workspace user
	test="`podman -v 2>&1`"
	if [ $? -eq 0 ]; then
		IFS=' ' read -ra ADDR <<< $test
		test=${ADDR[2]}
		echo "[$scriptName] Podman $test installed, run as root inside the container (do not attempt to mount home directory)"
		volumeOpt=:Z
		containerUser=root
	else
		containerUser=$(id -u)
		mountHome="$HOME"
	fi

	executeExpression "export MSYS_NO_PATHCONV=1"
	if [ -z "$mountHome" ] ; then
		executeExpression "docker run --tty --user $containerUser --volume '${workspace}:/solution/workspace${volumeOpt}' ${buildCommand} ${buildImage}:${newTag} automation/processor/buildPackage.sh '$BUILDNUMBER' '$REVISION' 'container_build'"
	else
		executeExpression "docker run --tty --user $containerUser --volume '${mountHome}:/solution/home${volumeOpt}' --volume '${workspace}:/solution/workspace${volumeOpt}' ${buildCommand} ${buildImage}:${newTag} automation/processor/buildPackage.sh '$BUILDNUMBER' '$REVISION' 'container_build'"
	fi

	echo "[$scriptName] List and remove all stopped containers"
	executeExpression 'docker ps --filter "status=exited" -a'
	exitedContainers=$(docker ps --filter "status=exited" -aq)
	if [ ! -z "$exitedContainers" ]; then
		executeExpression "docker rm $exitedContainers"
	fi

	if [ "$cleanupCDAF" == 'yes' ]; then
		executeExpression "rm -rf $absolute"
	fi

	if [ "$dockerfile_name" == 'yes' ]; then
		executeExpression "rm -f $dockerfile_name"
	fi
fi

echo; echo "[$scriptName] --- end ---"
