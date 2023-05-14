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
	executeExpression "echo \$registryToken | docker login --username $registryUser --password-stdin $registryURL"
}

function MASKED {
	CURRENT_IFS=$IFS
	IFS=$DEFAULT_IFS
	read -ra array <<< $(echo -n $1 | sha256sum)
	echo "${array[0]% *}" | tr '[:lower:]' '[:upper:]'
	IFS=$CURRENT_IFS
}

scriptName='imageBuild.sh'
workspace=$(pwd)

# example: imageBuild.sh ${SOLUTION}_${REVISION} ${BUILDNUMBER} ${runtimeImage} TasksLocal registry.example.org/${SOLUTION}:${BUILDNUMBER}
echo; echo "[$scriptName] --- start ---"
id=$1
if [ -z $id ]; then
	echo "[$scriptName]  id                   : (not supplied, login to Docker Registry only)"
	dockerLogin
else
	SOLUTION=${id%%_*}  # Use solution name for temp directory name
	echo "[$scriptName]  id                   : $id"
	BUILDNUMBER=$2
	if [ -z $BUILDNUMBER ]; then
		echo "[$scriptName]  BUILDNUMBER          : (not supplied, only push $id as latest)"
	else
		echo "[$scriptName]  BUILDNUMBER          : $BUILDNUMBER"

		containerImage=$3
		if [ -z $CONTAINER_IMAGE ]; then
			if [ -z "$containerImage" ]; then
				echo "[$scriptName] Environment variable CONTAINER_IMAGE not found and containerImage argument not passed!"; exit 2715
			else
				export CONTAINER_IMAGE="$containerImage"
				echo "[$scriptName]  CONTAINER_IMAGE      : $CONTAINER_IMAGE (set to argument passed)"
			fi
		else
			if [ -z "$containerImage" ]; then
				echo "[$scriptName]  CONTAINER_IMAGE      : $CONTAINER_IMAGE (previously set and containerImage argument not passed, no change made)"
			else
				echo "[$scriptName]  CONTAINER_IMAGE      : $containerImage (previously set to $CONTAINER_IMAGE)"
				export CONTAINER_IMAGE="$containerImage"
			fi
		fi

		# 2.2.0 extension for the support as integrated function
		constructor=$4
		if [ -z "$constructor" ]; then
			echo "[$scriptName]  constructor          : (not supplied, will process all directories, supports space separated list)"
		else
			echo "[$scriptName]  constructor          : $constructor (supports space separated list)"
		fi

		if [ -z "$CDAF_SKIP_PULL" ]; then
			echo "[$scriptName]  CDAF_SKIP_PULL       = (not supplied)"
		else
			echo "[$scriptName]  CDAF_SKIP_PULL       = $CDAF_SKIP_PULL"
		fi

		if [ -z "$CDAF_AUTOMATION_ROOT" ]; then
			CDAF_AUTOMATION_ROOT='./automation'
			if [ ! -d "${CDAF_AUTOMATION_ROOT}" ]; then
				CDAF_AUTOMATION_ROOT='../automation'
			else
				echo "[$scriptName]  CDAF_AUTOMATION_ROOT = $CDAF_AUTOMATION_ROOT (not set, using relative path)"
			fi
		else
			echo "[$scriptName]  CDAF_AUTOMATION_ROOT = $CDAF_AUTOMATION_ROOT"
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

		# 2.4.7 Support for DockerHub
		# 2.5.8 CDAF Solution property support, overriding environment variable.
		cdafRegURL=$(eval "echo $(${getProp} "${manifest}" "CDAF_REGISTRY_URL")")
		if [ -z "$cdafRegURL" ]; then
			if [ -z "$CDAF_REGISTRY_URL" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_URL    = (not supplied, do not set when pushing to Dockerhub)"
			else
				if [[ "$CDAF_REGISTRY_URL" == 'DOCKER-HUB' ]]; then
					echo "[$scriptName]  CDAF_REGISTRY_URL    = $CDAF_REGISTRY_URL (will not be set)"
				else
					echo "[$scriptName]  CDAF_REGISTRY_URL    = $CDAF_REGISTRY_URL (only pushes tagged image)"
					registryURL="$CDAF_REGISTRY_URL"
				fi
			fi
		else
			if [ -z "$CDAF_REGISTRY_URL" ]; then
				if [[ "$cdafRegURL" == 'DOCKER-HUB' ]]; then
					echo "[$scriptName]  CDAF_REGISTRY_URL    = $cdafRegURL (will not set to blank)"
				else
					echo "[$scriptName]  CDAF_REGISTRY_URL    = $cdafRegURL (only pushes tagged image)"
					registryURL="$cdafRegURL"
				fi
			else
				if [[ "$CDAF_REGISTRY_URL" == 'DOCKER-HUB' ]]; then
					echo "[$scriptName]  CDAF_REGISTRY_URL    = $cdafRegURL (loaded from manifest.txt, overiding environment variable $CDAF_REGISTRY_URL, will be set to blank)"
				else
					echo "[$scriptName]  CDAF_REGISTRY_URL    = $cdafRegURL (loaded from manifest.txt, overiding environment variable $CDAF_REGISTRY_URL, only pushes tagged image)"
					registryURL="$cdafRegURL"
				fi
			fi
		fi

		cdafRegTag=$(eval "echo $(${getProp} "${manifest}" "CDAF_REGISTRY_TAG")")
		if [ -z "$cdafRegTag" ]; then
			if [ -z "$CDAF_REGISTRY_TAG" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_TAG    = (not supplied, supports space separated list)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_TAG    = $CDAF_REGISTRY_TAG (loaded from environment variable, supports space separated list)"
				registryTag="$CDAF_REGISTRY_TAG"
			fi
		else
			if [ -z "$CDAF_REGISTRY_TAG" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_TAG    = $cdafRegTag (loaded from manifest.txt, supports space separated list)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_TAG    = $cdafRegTag (loaded from manifest.txt, overiding environment variable $CDAF_REGISTRY_TAG), supports space separated list"
			fi
			registryTag="$cdafRegTag"
		fi

		cdafRegUser=$(eval "echo $(${getProp} "${manifest}" "CDAF_REGISTRY_USER")")
		if [ -z "$cdafRegUser" ]; then
			if [ -z "$CDAF_REGISTRY_USER" ]; then
				registryUser='.'
				echo "[$scriptName]  CDAF_REGISTRY_USER   = $registryUser (default)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_USER   = $CDAF_REGISTRY_USER (loaded from environment variable)"
				registryUser="$CDAF_REGISTRY_USER"
			fi
		else
			if [ -z "$CDAF_REGISTRY_USER" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_USER   = $cdafRegUser (loaded from manifest.txt)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_USER   = $cdafRegUser (loaded from manifest.txt, overiding environment variable $CDAF_REGISTRY_USER)"
			fi
			registryUser="$cdafRegUser"
		fi

		cdafRegToken=$(eval "echo $(${getProp} "${manifest}" "CDAF_REGISTRY_TOKEN")")
		if [ -z "$cdafRegToken" ]; then
			if [ -z "$CDAF_REGISTRY_TOKEN" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_TOKEN  = (not supplied)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_TOKEN  = $(MASKED ${CDAF_REGISTRY_TOKEN}) (loaded from environment variable)"
				registryToken="$CDAF_REGISTRY_TOKEN"
			fi
		else
			if [ -z "$CDAF_REGISTRY_TOKEN" ]; then
				echo "[$scriptName]  CDAF_REGISTRY_TOKEN  = $(MASKED ${cdafRegToken}) (loaded from manifest.txt)"
			else
				echo "[$scriptName]  CDAF_REGISTRY_TOKEN  = $(MASKED ${cdafRegToken}) (loaded from manifest.txt, overiding environment variable \$CDAF_REGISTRY_TOKEN)"
			fi
			registryToken="$cdafRegToken"
		fi
	fi

	echo "[$scriptName]  pwd                  = $workspace"; echo

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
		if [ -z "$registryToken" ]; then
			echo "\$CDAF_REGISTRY_TOKEN not set, to push to registry set CDAF_REGISTRY_TAG, CDAF_REGISTRY_USER & CDAF_REGISTRY_TOKEN. Only set CDAF_REGISTRY_URL when not pushing to dockerhub"
		else
			executeExpression "echo $registryToken | docker login --username $registryUser --password-stdin $registryURL"
			for registryTag in ${registryTag}; do
				executeExpression "docker tag ${id}_${image##*/}:$BUILDNUMBER ${registryTag}"
				executeExpression "docker push ${registryTag}"
			done
		fi

	fi
fi

echo "[$scriptName] --- stop ---"
