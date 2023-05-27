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

manifest="${WORKSPACE}/manifest.txt"
if [ ! -f "$manifest" ]; then
	echo "[$scriptName] Manifest not found ($manifest)!"
	exit 5343
fi

# 2.6.0 CDAF Solution property support, with environment variable override.
if [ ! -z "$CDAF_REGISTRY_URL" ]; then
	registryURL="$CDAF_REGISTRY_URL"
	echo "[$scriptName]  CDAF_REGISTRY_URL    = $registryURL (loaded from environment variable)"
else
	registryURL=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_URL")")
	if [ ! -z "$registryURL" ]; then
		echo "[$scriptName]  CDAF_REGISTRY_URL    = $registryURL (loaded from manifest.txt)"
	else
		echo "[$scriptName]  CDAF_REGISTRY_URL    = (not supplied, do not set when pushing to Dockerhub)"
	fi
fi

if [ ! -z "$CDAF_REGISTRY_USER" ]; then
	registryUser="$CDAF_REGISTRY_USER"
	echo "[$scriptName]  CDAF_REGISTRY_USER   = $registryUser (loaded from environment variable)"
else
	cdafRegUser=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_USER")")
	if [ ! -z "$cdafRegUser" ]; then
		echo "[$scriptName]  CDAF_REGISTRY_USER   = $cdafRegUser (loaded from manifest.txt)"
	else
		registryUser='.'
		echo "[$scriptName]  CDAF_REGISTRY_USER   = $registryUser (default)"
	fi
fi

if [ ! -z "$CDAF_REGISTRY_TOKEN" ]; then
	registryToken="$CDAF_REGISTRY_TOKEN"
	echo "[$scriptName]  CDAF_REGISTRY_TOKEN  = $(MASKED ${registryToken}) (loaded from environment variable)"
else
	registryToken=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_TOKEN")")
	if [ ! -z "$registryToken" ]; then
		echo "[$scriptName]  CDAF_REGISTRY_TOKEN  = $(MASKED ${registryToken}) (loaded from manifest.txt)"
	else
		echo "[$scriptName]  CDAF_REGISTRY_TOKEN  = (not supplied)"
	fi
fi

if [ ! -z "$CDAF_REGISTRY_TAG" ]; then
	registryTag="$CDAF_REGISTRY_TAG"
	echo "[$scriptName]  CDAF_REGISTRY_TAG    = $registryTag (loaded from environment variable, supports space separated lis)"
else
	registryTag=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_TAG")")
	if [ ! -z "$registryTag" ]; then
		echo "[$scriptName]  CDAF_REGISTRY_TAG    = $registryTag (loaded from manifest.txt, supports space separated list)"
	else
		echo "[$scriptName]  CDAF_REGISTRY_TAG    = (not supplied, supports space separated list)"
	fi
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

		pushFeatureBranch=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "pushFeatureBranch")")
		if [ "$pushFeatureBranch" != 'yes' ]; then
			REVISION=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "REVISION")")
			defaultBranch=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "defaultBranch")")
			if [ -z "$defaultBranch" ]; then
				defaultBranch='master'
			fi
			if [ "$REVISION" != "$defaultBranch" ]; then
				echo "Do not push feature branch, set pushFeatureBranch=yes to force push, clearing registryToken"; echo
				unset registryToken
			fi
		fi

		if [ -z "$registryToken" ]; then
			echo; echo "CDAF_REGISTRY_TOKEN not set, to push to registry set CDAF_REGISTRY_TAG, CDAF_REGISTRY_USER & CDAF_REGISTRY_TOKEN. Only set CDAF_REGISTRY_URL when not pushing to dockerhub"; echo
		else
			dockerLogin
			for registryTag in ${registryTag}; do
				executeExpression "docker tag ${id}_${image##*/}:$BUILDNUMBER ${registryTag}"
				executeExpression "docker push ${registryTag}"
			done
		fi
	fi
fi

echo "[$scriptName] --- stop ---"; echo
