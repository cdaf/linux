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
imagebuild_workspace=$(pwd)

# example: imageBuild.sh ${SOLUTION}_${REVISION} ${BUILDNUMBER} ${runtimeImage} TasksLocal registry.example.org/${SOLUTION}:${BUILDNUMBER}
echo; echo "[$scriptName] --- start ---"
id=$1
if [ -z $id ]; then
	echo "[$scriptName]  id                   : (not supplied, login to Docker Registry only)"
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
				echo "[$scriptName]  CONTAINER_IMAGE      : $containerImage (set to argument passed)"
				baseImage="$containerImage"
			fi
		else
			if [ -z "$containerImage" ]; then
				echo "[$scriptName]  CONTAINER_IMAGE      : $CONTAINER_IMAGE (using environment variable)"
				baseImage="$CONTAINER_IMAGE"
			else
				echo "[$scriptName]  CONTAINER_IMAGE      : $containerImage (override environment variable $CONTAINER_IMAGE)"
				baseImage="$containerImage"
			fi
		fi

		# 2.2.0 extension for the support as integrated function
		constructor=$4
		if [ -z "$constructor" ]; then
			echo "[$scriptName]  constructor          : (not supplied, will process all directories, supports space separated list)"
		else
			echo "[$scriptName]  constructor          : $constructor (supports space separated list)"
		fi
	fi
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

manifest="./manifest.txt"
if [ ! -f "$manifest" ]; then
	manifest="${WORKSPACE}/manifest.txt"
fi

# 2.5.8 CDAF Solution property support, overriding environment variable.
# 2.4.7 Support for DockerHub
if [ -f "$manifest" ]; then
	cdafRegURL=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_URL")")
fi
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

if [ -f "$manifest" ]; then
	cdafRegTag=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_TAG")")
fi
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

if [ -f "$manifest" ]; then
	cdafRegUser=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_USER")")
fi
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

if [ -f "$manifest" ]; then
	cdafRegToken=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_TOKEN")")
fi
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

echo "[$scriptName]  pwd                  = $imagebuild_workspace"; echo

if [ -z $id ]; then
	if [ -z "$registryToken" ]; then
		echo "No arguments supplied and CDAF_REGISTRY_TOKEN not set so cannot login. Halt!"
		exit 5341
	fi
	dockerLogin
else

	if [ -z $BUILDNUMBER ]; then

		if [ -z "$registryToken" ]; then
			echo "Build Number not supplied and CDAF_REGISTRY_TOKEN not set so cannot login. Halt!"
			exit 5342
		fi
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
			executeExpression "./dockerBuild.sh ${id}_${image##*/} ${BUILDNUMBER} ${BUILDNUMBER} no $(whoami) $(id -u) ${baseImage}"
			executeExpression "cd $imagebuild_workspace"
		done

		if [ -f "$manifest" ]; then
			pushFeatureBranch=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "pushFeatureBranch")")
			REVISION=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "REVISION")")
			defaultBranch=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "defaultBranch")")
		else
			echo "Unable to load manifest, skipping push as cannot determine branch rules."; echo
		fi
		if [ -z "$REVISION" ]; then
			echo "Unable to read REVISION from manifest, skipping push as cannot determine branch rules."; echo
		else
			if [ -z "$defaultBranch" ]; then
				defaultBranch='master'
			fi
			if [ "$pushFeatureBranch" == 'yes' ] || [ "$REVISION" == "$defaultBranch" ]; then
				# 2.2.0 Integrated Registry push, not masking of secrets, it is expected the CI tool will know to mask these
				if [ -z "$registryToken" ]; then
					echo; echo "CDAF_REGISTRY_TOKEN not set, to push to registry set CDAF_REGISTRY_TAG, CDAF_REGISTRY_USER & CDAF_REGISTRY_TOKEN. Only set CDAF_REGISTRY_URL when not pushing to dockerhub"; echo
				else
					executeExpression "echo $registryToken | docker login --username $registryUser --password-stdin $registryURL"
					for registryTag in ${registryTag}; do
						executeExpression "docker tag ${id}_${image##*/}:$BUILDNUMBER ${registryTag}"
						executeExpression "docker push ${registryTag}"
					done
				fi
			else
				echo "Do not push feature branch, set pushFeatureBranch=yes to force push."; echo
			fi
		fi
	fi
fi

echo "[$scriptName] --- stop ---"; echo
