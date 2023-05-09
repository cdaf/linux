#!/usr/bin/env bash

function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][ERROR] Exception! $1 returned $exitCode"
		exit $exitCode
	fi
}  

function executeSuppress {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][WARN] $1 returned $exitCode"
		exit $exitCode
	fi
}  

function MASKED {
	CURRENT_IFS=$IFS
	IFS=$DEFAULT_IFS
	read -ra array <<< $(echo -n $1 | sha256sum)
	echo "${array[0]% *}" | tr '[:lower:]' '[:upper:]'
	IFS=$CURRENT_IFS
}

scriptName='dockerBuild.sh'

echo; echo "[$scriptName] Build docker image, resulting image tag will be ${imageName}:${tag}"; echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not supplied, exit with code 1."
	exit 1
else
	imageName=$(echo "$imageName" | tr '[:upper:]' '[:lower:]')
	echo "[$scriptName]  imageName                : $imageName"
fi

tag=$2
if [ -z "$tag" ]; then
	echo "[$scriptName]  tag not supplied"
else
	echo "[$scriptName]  tag                      : $tag"
fi

version=$3
if [ -z "$version" ]; then
	if [ ! -z "$tag" ]; then
		version=$tag
	    echo "[$scriptName]  version                  : $version (not supplied, defaulted to tag)"
	else
		version='0.0.0'
	    echo "[$scriptName]  version                  : $version (not supplied, and tag not passed, set to 0.0.0)"
	fi
else
	if [ "$version" == 'dockerfile' ]; then # Backward compatibility
		echo "[$scriptName]  version                  : $version (please set label in Dockerfile cdaf.${imageName}.image.version)"
	else
		echo "[$scriptName]  version                  : $version"
	fi
fi

rebuild=$4
if [ -z "$rebuild" ]; then
	echo "[$scriptName]  rebuild                  : (not supplied)"
else
	echo "[$scriptName]  rebuild                  : $rebuild"
fi

userName=$5
if [ -z "$userName" ]; then
	echo "[$scriptName]  userName                 : (not supplied)"
else
	echo "[$scriptName]  userName                 : $userName"
fi

userID=$6
if [ -z "$userID" ]; then
	echo "[$scriptName]  userID                   : (not supplied)"
else
	echo "[$scriptName]  userID                   : $userID"
	echo "[$scriptName]  CDAF_PULL_REGISTRY_URL   = (not supplied, do not set when pushing to Dockerhub)"
fi

if [ -z "$CDAF_AUTOMATION_ROOT" ]; then
	CDAF_AUTOMATION_ROOT='./automation'
	if [ ! -d "${CDAF_AUTOMATION_ROOT}" ]; then
		CDAF_AUTOMATION_ROOT='../automation'
	else
		echo "[$scriptName]  CDAF_AUTOMATION_ROOT     = $CDAF_AUTOMATION_ROOT (not set, using relative path)"
	fi
else
	echo "[$scriptName]  CDAF_AUTOMATION_ROOT     = $CDAF_AUTOMATION_ROOT"
fi

if [ -f "${CDAF_AUTOMATION_ROOT}/remote/getProperty.sh" ]; then
	getProp="${CDAF_AUTOMATION_ROOT}/remote/getProperty.sh"
else
	getProp="${WORKSPACE}/getProperty.sh"
fi

manifest="./manifest.txt"
if [ ! -f "$manifest" ]; then
	manifest="${WORKSPACE}/manifest.txt"
fi

# 2.5.8 Image from Private Registry
if [ -z "$CDAF_PULL_REGISTRY_URL" ]; then
	export CDAF_PULL_REGISTRY_URL=$(eval "echo $(${getProp} "${manifest}" "CDAF_PULL_REGISTRY_URL")")
	if [ -z "$CDAF_PULL_REGISTRY_URL" ]; then
		echo "[$scriptName]  CDAF_PULL_REGISTRY_URL   = (not supplied, do not set when pushing to Dockerhub)"
	else
		if [[ "$CDAF_PULL_REGISTRY_URL" == 'DOCKER-HUB' ]]; then
			echo "[$scriptName]  CDAF_PULL_REGISTRY_URL   = $CDAF_PULL_REGISTRY_URL (loaded from ${manifest}, will be set to blank)"
		else
			echo "[$scriptName]  CDAF_PULL_REGISTRY_URL   = $CDAF_PULL_REGISTRY_URL (loaded from ${manifest}, only pushes tagged image)"
			registryURL="$CDAF_PULL_REGISTRY_URL"
		fi
	fi
else
	if [[ "$CDAF_PULL_REGISTRY_URL" == 'DOCKER-HUB' ]]; then
		echo "[$scriptName]  CDAF_PULL_REGISTRY_URL   = $CDAF_PULL_REGISTRY_URL (will be set to blank)"
	else
		echo "[$scriptName]  CDAF_PULL_REGISTRY_URL   = $CDAF_PULL_REGISTRY_URL (only pushes tagged image)"
		registryURL="$CDAF_PULL_REGISTRY_URL"
	fi
fi

if [ -z "$CDAF_PULL_REGISTRY_USER" ]; then
	export CDAF_PULL_REGISTRY_USER=$(eval "echo $(${getProp} "${manifest}" "CDAF_PULL_REGISTRY_USER")")
	if [ -z "$CDAF_PULL_REGISTRY_USER" ]; then
		echo "[$scriptName]  CDAF_PULL_REGISTRY_USER  = (not supplied, push will not be attempted)"
	else
		echo "[$scriptName]  CDAF_PULL_REGISTRY_USER  = $CDAF_PULL_REGISTRY_USER (loaded from ${manifest})"
	fi
else
	echo "[$scriptName]  CDAF_PULL_REGISTRY_USER  = $CDAF_PULL_REGISTRY_USER"
fi

if [ -z "$CDAF_PULL_REGISTRY_TOKEN" ]; then
	export CDAF_PULL_REGISTRY_TOKEN=$(eval "echo $(${getProp} "${manifest}" "CDAF_PULL_REGISTRY_TOKEN")")
	if [ -z "$CDAF_PULL_REGISTRY_TOKEN" ]; then
		echo "[$scriptName]  CDAF_PULL_REGISTRY_TOKEN = (not supplied)"
	else
		echo "[$scriptName]  CDAF_PULL_REGISTRY_TOKEN = $(MASKED ${CDAF_PULL_REGISTRY_TOKEN}) (loaded from ${manifest})"
	fi
else
	echo "[$scriptName]  CDAF_PULL_REGISTRY_TOKEN = $(MASKED ${CDAF_PULL_REGISTRY_TOKEN})"
fi

if [ -z "$CDAF_SKIP_PULL" ]; then
	echo "[$scriptName]  CDAF_SKIP_PULL           = (not supplied)"
else
	echo "[$scriptName]  CDAF_SKIP_PULL           = $CDAF_SKIP_PULL"
fi

if [ ! -z "$CDAF_PULL_REGISTRY_URL" ]; then
	echo; echo "[$scriptName] CDAF_PULL_REGISTRY_URL set, attempt login..."
	executeExpression "echo \$CDAF_PULL_REGISTRY_TOKEN | docker login --username $CDAF_PULL_REGISTRY_USER --password-stdin $registryURL"
fi

echo; echo "[$scriptName] List existing images..."
executeExpression "docker images -f label=cdaf.${imageName}.image.version"

echo "[$scriptName] As of 1.13.0 new prune commands, if using older version, suppress error"
executeSuppress "docker system prune -f"

buildCommand='docker build --progress plain'

if [ ! -z "$tag" ]; then
	buildCommand+=" --build-arg BUILD_TAG=${tag}"
fi

if [ "$rebuild" == 'yes' ]; then
	buildCommand+=" --no-cache=true"
fi

if [ ! -z "$userName" ]; then
	buildCommand+=" --build-arg userName=$userName"
fi

if [ ! -z "$userID" ]; then
	buildCommand+=" --build-arg userID=$userID"
fi

if [ ! -z "$tag" ]; then
	buildCommand+=" --tag ${imageName}:${tag}"
else
	buildCommand+=" --tag ${imageName}"
fi

if [ ! -z "$CONTAINER_IMAGE" ]; then
	echo; echo "[$scriptName] \$CONTAINER_IMAGE is set (${CONTAINER_IMAGE}), pass as \$CONTAINER_IMAGE to build"
	buildCommand+=" --build-arg CONTAINER_IMAGE=${CONTAINER_IMAGE}"
	if [ "$CDAF_SKIP_PULL" != 'yes' ]; then
		executeExpression "docker pull ${CONTAINER_IMAGE}"
	fi
fi

for envVar in $(env | grep CDAF_IB_); do
	envVar=$(echo ${envVar//CDAF_IB_})
	buildCommand+=" --build-arg ${envVar}"
done

if [ "$version" != 'dockerfile' ]; then
	# Apply required label for CDAF image management
	buildCommand+=" --label=cdaf.${imageName}.image.version=${version}"
fi

echo
export PROGRESS_NO_TRUNC='1'
executeExpression "$buildCommand ."

echo; echo "[$scriptName] List Resulting images..."
executeExpression "docker images -f label=cdaf.${imageName}.image.version"

echo; echo "[$scriptName] --- end ---"
