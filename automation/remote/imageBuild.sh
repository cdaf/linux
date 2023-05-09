#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

function dockerLogin {
	executeExpression "echo \$CDAF_REGISTRY_TOKEN | docker login --username $CDAF_REGISTRY_USER --password-stdin $registryURL"
}

function MASKED {
	CURRENT_IFS=$IFS
	IFS=$DEFAULT_IFS
	read -ra array <<< $(echo -n $1 | sha256sum)
	echo "${array[0]}" | tr '[:lower:]' '[:upper:]'
	IFS=$CURRENT_IFS
}

scriptName='imageBuild.sh'
workspace=$(pwd)

# example: imageBuild.sh ${SOLUTION}_${REVISION} ${BUILDNUMBER} ${runtimeImage} TasksLocal registry.example.org/${SOLUTION}:${BUILDNUMBER}
echo; echo "[$scriptName] --- start ---"
id=$1
if [ -z $id ]; then
	echo "[$scriptName]  id                    : (not supplied, login to Docker Registry only)"
	dockerLogin
else
	SOLUTION=${id%%_*}  # Use solution name for temp directory name
	echo "[$scriptName]  id                    : $id"
	BUILDNUMBER=$2
	if [ -z $BUILDNUMBER ]; then
		echo "[$scriptName]  BUILDNUMBER           : (not supplied, only push $id as latest)"
	else
		echo "[$scriptName]  BUILDNUMBER           : $BUILDNUMBER"

		containerImage=$3
		if [ -z $CONTAINER_IMAGE ]; then
			if [ -z "$containerImage" ]; then
				echo "[$scriptName] Environment variable CONTAINER_IMAGE not found and containerImage argument not passed!"; exit 2715
			else
				export CONTAINER_IMAGE="$containerImage"
				echo "[$scriptName]  CONTAINER_IMAGE       : $CONTAINER_IMAGE (set to argument passed)"
			fi
		else
			echo "[$scriptName]  CONTAINER_IMAGE       : $CONTAINER_IMAGE (not changed as already set)"
		fi

		# 2.2.0 extension for the support as integrated function
		constructor=$4
		if [ -z "$constructor" ]; then
			echo "[$scriptName]  constructor           : (not supplied, will process all directories, supports space separated list)"
		else
			echo "[$scriptName]  constructor           : $constructor (supports space separated list)"
		fi

		if [ -z "$CDAF_SKIP_PULL" ]; then
			echo "[$scriptName]  CDAF_SKIP_PULL        = (not supplied)"
		else
			echo "[$scriptName]  CDAF_SKIP_PULL        = $CDAF_SKIP_PULL"
		fi

		if [ -z "$CDAF_AUTOMATION_ROOT" ]; then
			CDAF_AUTOMATION_ROOT='../automation'
			echo "[$scriptName]  CDAF_AUTOMATION_ROOT  = $CDAF_AUTOMATION_ROOT (not set, using relative path)"
		else
			echo "[$scriptName]  CDAF_AUTOMATION_ROOT  = $CDAF_AUTOMATION_ROOT"
		fi

		# 2.4.7 Support for DockerHub
		if [ -z "$CDAF_REGISTRY_URL" ]; then
			export CDAF_REGISTRY_URL=$(eval "echo $(${CDAF_AUTOMATION_ROOT}/remote/getProperty.sh "manifest.txt" "CDAF_REGISTRY_URL")")
			if [ -z "$CDAF_REGISTRY_URL" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_URL     = (not supplied, do not set when pushing to Dockerhub)"
			else
				if [[ "$CDAF_REGISTRY_URL" == 'DOCKER-HUB' ]]; then
					echo "[$scriptName]  CDAF_REGISTRY_URL     = $CDAF_REGISTRY_URL (loaded from manifest.txt, will be set to blank)"
				else
					echo "[$scriptName]  CDAF_REGISTRY_URL     = $CDAF_REGISTRY_URL (loaded from manifest.txt, only pushes tagged image)"
					registryURL="$CDAF_REGISTRY_URL"
				fi
			fi
		else
			if [[ "$CDAF_REGISTRY_URL" == 'DOCKER-HUB' ]]; then
				echo "[$scriptName]  CDAF_REGISTRY_URL     = $CDAF_REGISTRY_URL (will be set to blank)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_URL     = $CDAF_REGISTRY_URL (only pushes tagged image)"
				registryURL="$CDAF_REGISTRY_URL"
			fi
		fi

		if [ -z "$CDAF_REGISTRY_TAG" ]; then
			export CDAF_REGISTRY_TAG=$(eval "echo $(${CDAF_AUTOMATION_ROOT}/remote/getProperty.sh "manifest.txt" "CDAF_REGISTRY_TAG")")
			if [ -z "$CDAF_REGISTRY_TAG" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_TAG     = (not supplied, supports space separated list)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_TAG   = $CDAF_REGISTRY_TAG (loaded from manifest.txt)"
			fi
		else
			echo "[$scriptName]  CDAF_REGISTRY_TAG     = $CDAF_REGISTRY_TAG (supports space separated list)"
		fi

		if [ -z "$CDAF_REGISTRY_USER" ]; then
			export CDAF_REGISTRY_USER=$(eval "echo $(${CDAF_AUTOMATION_ROOT}/remote/getProperty.sh "manifest.txt" "CDAF_REGISTRY_USER")")
			if [ -z "$CDAF_REGISTRY_USER" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_USER    = (not supplied, push will not be attempted)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_USER    = $CDAF_REGISTRY_USER (loaded from manifest.txt)"
			fi
		else
			echo "[$scriptName]  CDAF_REGISTRY_USER    = $CDAF_REGISTRY_USER"
		fi

		if [ -z "$CDAF_REGISTRY_TOKEN" ]; then
			export CDAF_REGISTRY_TOKEN=$(eval "echo $(${CDAF_AUTOMATION_ROOT}/remote/getProperty.sh "manifest.txt" "CDAF_REGISTRY_TOKEN")")
			if [ -z "$CDAF_REGISTRY_TOKEN" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_TOKEN   = (not supplied)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_TOKEN   = $(MASKED ${CDAF_REGISTRY_TOKEN}) (loaded from manifest.txt)"
			fi
		else
			echo "[$scriptName]  CDAF_REGISTRY_TOKEN   = $(MASKED ${CDAF_REGISTRY_TOKEN})"
		fi
	fi

	echo "[$scriptName]  pwd                   = $workspace"; echo

	if [ -z $BUILDNUMBER ]; then

		dockerLogin
		noTag=$(echo "${id%:*}")
		if [ -z "$registryURL" ]; then
			executeExpression "docker tag ${id} ${noTag}:latest"
			executeExpression "docker push ${noTag}:latest"
		else
			executeExpression "docker tag $registryURL/${id} $registryURL/${noTag}:latest"
			executeExpression "docker push $registryURL/${noTag}:latest"
		fi

	else

		transient="/tmp/${SOLUTION}/${id}"

		if [ -d "${transient}" ]; then
			echo "Build directory ${transient} already exists"
		else
			executeExpression "mkdir -p ${transient}"
		fi

		if [ -z "$constructor" ]; then
			constructor=$(find . -mindepth 1 -maxdepth 1 -type d)
		fi

		for image in $constructor; do

			echo; echo "------------------------"
			echo "   ${image##*/}"
			echo "------------------------"; echo
			executeExpression "rm -rf ${transient}/**"
			if [ -d "$CDAF_AUTOMATION_ROOT" ]; then
				executeExpression "cp -r $CDAF_AUTOMATION_ROOT ${transient}"
			else
				echo "[WARN] CDAF not found in $CDAF_AUTOMATION_ROOT"
			fi
			if [ -f "../dockerBuild.sh" ]; then
				executeExpression "cp ../dockerBuild.sh ${transient}"
			else
				executeExpression "cp $CDAF_AUTOMATION_ROOT/remote/dockerBuild.sh ${transient}"
			fi
			executeExpression "cp -r ${image}/** ${transient}"
			executeExpression "cd ${transient}"
			executeExpression "cat Dockerfile"
			image=$(echo "$image" | tr '[:upper:]' '[:lower:]')
			executeExpression "./dockerBuild.sh ${id}_${image##*/} ${BUILDNUMBER} ${BUILDNUMBER} no $(whoami) $(id -u) ${CONTAINER_IMAGE}"
			executeExpression "cd $workspace"
		done

		# 2.2.0 Integrated Registry push, not masking of secrets, it is expected the CI tool will know to mask these
		if [ -z "$CDAF_REGISTRY_USER" ]; then
			echo "\$CDAF_REGISTRY_USER not set, to push to registry set CDAF_REGISTRY_URL, CDAF_REGISTRY_TAG, CDAF_REGISTRY_USER & CDAF_REGISTRY_TOKEN"
			echo "Do not set CDAF_REGISTRY_URL when pushing to dockerhub"
		else
			executeExpression "echo $CDAF_REGISTRY_TOKEN | docker login --username $CDAF_REGISTRY_USER --password-stdin $registryURL"
			for registryTag in ${CDAF_REGISTRY_TAG}; do
				executeExpression "docker tag ${id}_${image##*/}:$BUILDNUMBER ${registryTag}"
				executeExpression "docker push ${registryTag}"
			done
		fi

	fi
fi

echo "[$scriptName] --- stop ---"
