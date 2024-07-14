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

# Default call process is : ${CDAF_CORE}/imageBuild.sh ${SOLUTION}_${REVISION} ${BUILDNUMBER} ${buildImage} ${LOCAL_WORK_DIR}
# an example call to build all child directories (non-recursive) : ${CDAF_CORE}/imageBuild.sh ${SOLUTION}_${REVISION} ${BUILDNUMBER} ${buildImage}
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

		baseImage=$3
		if [ -z "$baseImage" ]; then
			echo "[$scriptName]  baseImage            : (not supplied)"
		else
			echo "[$scriptName]  baseImage            : $baseImage"
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

if [ -z "$AUTOMATIONROOT" ]; then
	AUTOMATIONROOT='./automation'
	if [ ! -d "${AUTOMATIONROOT}" ]; then
		AUTOMATIONROOT='../automation'
	else
		echo "[$scriptName]  AUTOMATIONROOT       = $AUTOMATIONROOT (not set, using relative path)"
	fi
else
	echo "[$scriptName]  AUTOMATIONROOT       = $AUTOMATIONROOT"
fi

# 2.6.0 Push Private Registry
manifest="${WORKSPACE}/manifest.txt"
if [ ! -f "$manifest" ]; then
	manifest="${SOLUTIONROOT}/CDAF.solution"
	if [ ! -f "$manifest" ]; then
		echo "[$scriptName] Properties not found in ${WORKSPACE}\manifest.txt or ${manifest}!"
		exit 5343
	fi
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
	registryUser=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_USER")")
	if [ ! -z "$registryUser" ]; then
		echo "[$scriptName]  CDAF_REGISTRY_USER   = $registryUser (loaded from manifest.txt)"
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
	registryTags="$CDAF_REGISTRY_TAG"
	echo "[$scriptName]  CDAF_REGISTRY_TAG    = $registryTags (loaded from environment variable, supports space separated list)"
else
	registryTags=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_REGISTRY_TAG")")
	if [ ! -z "$registryTags" ]; then
		echo "[$scriptName]  CDAF_REGISTRY_TAG    = $registryTags (loaded from manifest.txt, supports space separated list)"
	else
		registryTags='latest'
		echo "[$scriptName]  CDAF_REGISTRY_TAG    = $registryTags (default, supports space separated list)"
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
			executeExpression "mkdir -p '${transient}'"
		fi

		if [ -z "$constructor" ]; then
			constructor=()
			while IFS=  read -r -d $'\0'; do
				constructor+=("$REPLY")
			done < <(find . -mindepth 1 -maxdepth 1 -type d -print0)
		fi

		if [ ! -z "$constructor" ]; then
			IFS=$'\n' constructor=($(sort <<<"${constructor[*]}"))
			unset IFS
			echo; echo "[$scriptName] Preparing to process constructors : "; echo		 
			for image in "${constructor[@]}"; do
				echo "  ${image##*/}"
			done
		fi

		for image in "${constructor[@]}"; do

			echo; echo "------------------------"
			echo "   ${image##*/}"
			echo "------------------------"; echo
			executeExpression "rm -rf \"${transient}\"/**"
			if [ -d "$AUTOMATIONROOT" ]; then
				executeExpression "cp -r '$AUTOMATIONROOT' ${transient}"
			else
				echo "[WARN] CDAF not found in $AUTOMATIONROOT"
			fi

			executeExpression "cp -r \"${image}\"/** ${transient}"
			executeExpression "cd '${transient}'"

			# 2.6.2 Check and remove default dockerfile, i.e. after previously failed build
			if [[ $(cat './Dockerfile' 2> /dev/null | grep 'CDAF Default Dockerfile') ]]; then
				echo; echo "[$scriptName] default dockerfile found, removing..."
				executeExpression "rm './Dockerfile'"
			fi

			image=$(echo "$image" | tr '[:upper:]' '[:lower:]')
			export CONTAINER_IMAGE="${baseImage}"
			executeExpression "'${CDAF_CORE}/dockerBuild.sh' ${id}_${image##*/} ${BUILDNUMBER} no $(whoami) $(id -u)"
			executeExpression "cd '$imagebuild_workspace'"
		done

		pushFeatureBranch=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "pushFeatureBranch")")
		if [ "$pushFeatureBranch" != 'yes' ]; then
			REVISION=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "REVISION")")
			defaultBranch=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "defaultBranch")")
			if [ -z "$defaultBranch" ]; then
				defaultBranch='master'
			fi
			if [ "$REVISION" != "$defaultBranch" ]; then
				echo "defaultBranch = $defaultBranch"
				echo "Do not push feature branch ($REVISION), set pushFeatureBranch=yes to force push."
				skipPush='yes'
			fi
		fi

		if [ "$skipPush" != 'yes' ]; then
			if [ -z "$registryToken" ]; then
				echo; echo "CDAF_REGISTRY_TOKEN not set, to push to registry set CDAF_REGISTRY_TAG, CDAF_REGISTRY_USER & CDAF_REGISTRY_TOKEN. Only set CDAF_REGISTRY_URL when not pushing to dockerhub"; echo
			else
				dockerLogin
				for tag in ${registryTags}; do
					executeExpression "docker tag ${id}_${image##*/}:$BUILDNUMBER ${tag}"
					executeExpression "docker push ${tag}"
				done
			fi
		fi
	fi
fi

echo "[$scriptName] --- stop ---"; echo
