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
	if [ -f manifest.txt ]; then
		echo; echo "[$scriptName] Loading registry properties from manifest.txt..."
	else
		echo; echo "[$scriptName] manifest.txt file not found! If processing from CI context, use wrap.tsk driver."; echo
		exit 6630
	fi

	export CDAF_REGISTRY_USER=$(eval "echo $(./getProperty.sh "manifest.txt" "CDAF_REGISTRY_USER")")
	if [ -z "$CDAF_REGISTRY_USER" ]; then
		echo "[$scriptName]  CDAF_REGISTRY_USER not supplied! User credentials required for publishing."
		exit 6631
	else
		echo "[$scriptName]  CDAF_REGISTRY_USER  = $CDAF_REGISTRY_USER"
	fi

	export CDAF_REGISTRY_TOKEN=$(eval "echo $(./getProperty.sh "manifest.txt" "CDAF_REGISTRY_TOKEN")")
	if [ -z "$CDAF_REGISTRY_TOKEN" ]; then
		echo "[$scriptName]  CDAF_REGISTRY_TOKEN not supplied! User credentials required for publishing."
		exit 6632
	else
		echo "[$scriptName]  CDAF_REGISTRY_TOKEN = $CDAF_REGISTRY_TOKEN"
	fi

	export CDAF_REGISTRY_URL=$(eval "echo $(./getProperty.sh "manifest.txt" "CDAF_REGISTRY_URL")")
	if [ -z "$CDAF_REGISTRY_URL" ]; then
		echo "[$scriptName]  CDAF_REGISTRY_URL   = (not supplied, do not set when pushing to Dockerhub)"
	else
		echo "[$scriptName]  CDAF_REGISTRY_URL   = $CDAF_REGISTRY_URL"
	fi

	executeExpression "echo \$CDAF_REGISTRY_TOKEN | docker login --username $CDAF_REGISTRY_USER --password-stdin $CDAF_REGISTRY_URL"
}

scriptName='imageBuild.sh'

# example: imageBuild.sh ${SOLUTION}_${REVISION} ${BUILDNUMBER} ${runtimeImage} TasksLocal registry.example.org/${SOLUTION}:${BUILDNUMBER}
echo; echo "[$scriptName] --- start ---"
id=$1
if [ -z $id ]; then
	echo "[$scriptName]  id                    : (not supplied, login to Docker Registry only)"
	dockerLogin
else
	id=${id##*/}
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

		if [ -z "$CDAF_REGISTRY_URL" ]; then
			echo "[$scriptName]  CDAF_REGISTRY_URL     : (not supplied)"
		else
			echo "[$scriptName]  CDAF_REGISTRY_URL     : $CDAF_REGISTRY_URL (only pushes tagged image)"
		fi

		if [ -z "$CDAF_REGISTRY_TAG" ]; then
			echo "[$scriptName]  CDAF_REGISTRY_TAG     : (not supplied)"
		else
			echo "[$scriptName]  CDAF_REGISTRY_TAG     : $CDAF_REGISTRY_TAG"
		fi

		if [ -z "$CDAF_REGISTRY_USER" ]; then
			echo "[$scriptName]  CDAF_REGISTRY_USER    : (not supplied, push will not be attempted)"
		else
			echo "[$scriptName]  CDAF_REGISTRY_USER    : $CDAF_REGISTRY_USER"
		fi

		if [ -z "$CDAF_REGISTRY_TOKEN" ]; then
			echo "[$scriptName]  CDAF_REGISTRY_TOKEN   : (not supplied)"
		else
			echo "[$scriptName]  CDAF_REGISTRY_TOKEN   : $CDAF_REGISTRY_TOKEN"
		fi

		if [ -z "$CDAF_AUTOMATION_ROOT" ]; then
			CDAF_AUTOMATION_ROOT='../automation'
			echo "[$scriptName]  CDAF_AUTOMATION_ROOT  : $CDAF_AUTOMATION_ROOT (not set, using relative path)"
		else
			echo "[$scriptName]  CDAF_AUTOMATION_ROOT  : $CDAF_AUTOMATION_ROOT"
		fi
	fi

	workspace=$(pwd)
	echo "[$scriptName]  pwd                   : $workspace"; echo

	if [ -z $BUILDNUMBER ]; then

		dockerLogin
		noTag=$(echo "${id%:*}")
		if [ -z "$CDAF_REGISTRY_URL" ]; then
			executeExpression "docker tag ${id} ${noTag}:latest"
			executeExpression "docker push ${noTag}:latest"
		else
			executeExpression "docker tag $CDAF_REGISTRY_URL/${id} $CDAF_REGISTRY_URL/${noTag}:latest"
			executeExpression "docker push $CDAF_REGISTRY_URL/${noTag}:latest"
		fi

	else

		transient="/tmp/buildImage/${id}"

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
			if [ -f "../dockerClean.sh" ]; then
				executeExpression "cp ../dockerClean.sh ${transient}"
			else
				executeExpression "cp $CDAF_AUTOMATION_ROOT/remote/dockerClean.sh ${transient}"
			fi
			executeExpression "cp -r ${image}/** ${transient}"
			executeExpression "cd ${transient}"
			executeExpression "cat Dockerfile"
			image=$(echo "$image" | tr '[:upper:]' '[:lower:]')
			executeExpression "./dockerBuild.sh ${id}_${image##*/} $BUILDNUMBER $BUILDNUMBER no $(whoami) $(id -u)"
			executeExpression "./dockerClean.sh ${id}_${image##*/} $BUILDNUMBER"
			executeExpression "cd $workspace"
		done
		# 2.2.0 Integrated Registry push, not masking of secrets, it is expected the CI tool will know to mask these
		if [ -z "$CDAF_REGISTRY_USER" ]; then
			echo "\$CDAF_REGISTRY_USER not set, to push to registry set CDAF_REGISTRY_URL, CDAF_REGISTRY_TAG, CDAF_REGISTRY_USER & CDAF_REGISTRY_TOKEN"
			echo "Do not set CDAF_REGISTRY_URL when pushing to dockerhub"
		else
			executeExpression "echo $CDAF_REGISTRY_TOKEN | docker login --username $CDAF_REGISTRY_USER --password-stdin $CDAF_REGISTRY_URL"
			executeExpression "docker tag ${id}_${image##*/}:$BUILDNUMBER ${CDAF_REGISTRY_TAG}"
			executeExpression "docker push ${CDAF_REGISTRY_TAG}"
		fi

	fi
fi

echo "[$scriptName] --- stop ---"
