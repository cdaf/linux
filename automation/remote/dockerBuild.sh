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
	echo "[$scriptName] imageName not supplied, exit with code 1114."
	exit 1111
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

rebuild=$3
if [ -z "$rebuild" ]; then
	echo "[$scriptName]  rebuild                  : (not supplied)"
else
	echo "[$scriptName]  rebuild                  : $rebuild"
fi

userName=$4
if [ -z "$userName" ]; then
	echo "[$scriptName]  userName                 : (not supplied)"
else
	echo "[$scriptName]  userName                 : $userName"
fi

userID=$5
if [ -z "$userID" ]; then
	echo "[$scriptName]  userID                   : (not supplied)"
else
	echo "[$scriptName]  userID                   : $userID"
fi

optionalArgs=$6
if [ -z "$optionalArgs" ]; then
	echo "[$scriptName]  optionalArgs             : (not supplied)"
else
	echo "[$scriptName]  optionalArgs             : $optionalArgs"
fi

getProp="${CDAF_CORE}/getProperty.sh"

# 2.6.0 Image from Private Registry
manifest="${CDAF_CORE}/manifest.txt"
if [ ! -f "$manifest" ]; then
	manifest="${SOLUTIONROOT}/CDAF.solution"
	if [ ! -f "$manifest" ]; then
		echo "[$scriptName] Properties not found in ${CDAF_CORE}/manifest.txt or ${manifest}!"
		exit 1114
	fi
fi

baseImage=$7
if [ ! -z "$baseImage" ]; then
	if [ ! -z "$CONTAINER_IMAGE" ]; then
		echo "[$scriptName]  baseImage                : $baseImage (override environment variable '${CONTAINER_IMAGE}')"
	else
		echo "[$scriptName]  baseImage                : $baseImage"
	fi
else
	if [ ! -z "$CONTAINER_IMAGE" ]; then
		baseImage="$CONTAINER_IMAGE"
		echo "[$scriptName]  baseImage                : $baseImage (loaded from environment variable CONTAINER_IMAGE)"
	else

		# If an explicit image is not defined, perform implicit cascading load
		baseImage=$(eval "echo $("${getProp}" "${manifest}" "runtimeImage")")
		if [ ! -z "$baseImage" ]; then
			echo "[$scriptName]  baseImage                : $baseImage (not supplied, using runtimeImage property)"
		else
			baseImage=$(eval "echo $("${getProp}" "${manifest}" "containerImage")")
			if [ ! -z "$runtimeImage" ]; then
				echo "[$scriptName]  baseImage                : $baseImage (not supplied, using containerImage property)"
			else
				echo "[$scriptName]  baseImage                : (baseImage not supplied or determined, hardcoded image required in Dockerfile)"
			fi
		fi
	fi
fi

if [ ! -z "$CDAF_PULL_REGISTRY_URL" ]; then
	registryPullURL="$CDAF_PULL_REGISTRY_URL"
	echo "[$scriptName]  CDAF_PULL_REGISTRY_URL   = $registryPullURL (loaded from manifest.txt)"
else
	registryPullURL=$(eval "echo $("${getProp}" "${manifest}" "CDAF_PULL_REGISTRY_URL")")
	if [ ! -z "$registryPullURL" ]; then
		echo "[$scriptName]  CDAF_PULL_REGISTRY_URL   = $registryPullURL (loaded from manifest.txt)"
	else
		echo "[$scriptName]  CDAF_PULL_REGISTRY_URL   = (not supplied, do not set when pulling from Dockerhub)"
	fi
fi

if [ ! -z "$CDAF_PULL_REGISTRY_USER" ]; then
	registryPullUser="$CDAF_PULL_REGISTRY_USER"
	echo "[$scriptName]  CDAF_PULL_REGISTRY_USER  = $registryPullUser (using environment variable)"
else
	registryPullUser=$(eval "echo $("${getProp}" "${manifest}" "CDAF_PULL_REGISTRY_USER")")
	if [ ! -z "$registryPullUser" ]; then
		echo "[$scriptName]  CDAF_PULL_REGISTRY_USER  = $registryPullUser (loaded from manifest.txt)"
	else
		registryPullUser='.'
		echo "[$scriptName]  CDAF_PULL_REGISTRY_USER  = $registryPullUser (default)"
	fi
fi

if [ ! -z "$CDAF_PULL_REGISTRY_TOKEN" ]; then
	registryPullToken="$CDAF_PULL_REGISTRY_TOKEN"
	echo "[$scriptName]  CDAF_PULL_REGISTRY_TOKEN = $(MASKED ${registryPullToken}) (from environment variable)"
else
	registryPullToken=$(eval "echo $("${getProp}" "${manifest}" "CDAF_PULL_REGISTRY_TOKEN")")
	if [ ! -z "$registryPullToken" ]; then
		echo "[$scriptName]  CDAF_PULL_REGISTRY_TOKEN = $(MASKED ${registryPullToken}) (loaded from manifest.txt)"
	else
		echo "[$scriptName]  CDAF_PULL_REGISTRY_TOKEN = (not supplied, login will not be attempted)"
	fi
fi

if [ ! -z "$CDAF_SKIP_PULL" ]; then
	skipPull="$CDAF_SKIP_PULL"
	echo "[$scriptName]  CDAF_SKIP_PULL           = $skipPull"
else
	skipPull=$(eval "echo $("${getProp}" "${manifest}" "CDAF_SKIP_PULL")")
	if [ ! -z "$skipPull" ]; then
		echo "[$scriptName]  CDAF_SKIP_PULL           = $skipPull (loaded from manifest.txt)"
	else
		skipPull='no'
		echo "[$scriptName]  CDAF_SKIP_PULL           = $skipPull (default)"
	fi
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

if [ ! -z "$registryPullToken" ]; then
	echo; echo "[$scriptName] CDAF_PULL_REGISTRY_TOKEN set, attempt login..."
	executeExpression "echo \$registryPullToken | docker login --username $registryPullUser --password-stdin $registryPullURL"
fi

if [ ! -z "$baseImage" ]; then
	echo; echo "[$scriptName] CONTAINER_IMAGE is set (${baseImage})"
	buildCommand+=" --build-arg CONTAINER_IMAGE=${baseImage}"
	if [ "$skipPull" != 'yes' ]; then
		executeExpression "docker pull ${baseImage}"
	fi
fi

for envVar in $(env | grep CDAF_IB_); do
	envVar=$(echo ${envVar//CDAF_IB_})
	buildCommand+=" --build-arg ${envVar}"
done

buildCommand+=" --label=cdaf.${imageName}.image.version=${tag}"

if [ -f './Dockerfile' ]; then
	dockerfile_name='Dockerfile'
	executeExpression "cat ./Dockerfile"
else # 2.8.0 default Dockerfilefile
	dockerfile_name='Dockerfile-db-temp'
	echo; echo "[$scriptName] ./Dockerfile not found, creating default"; echo

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

echo
export PROGRESS_NO_TRUNC='1'
executeExpression "$buildCommand --file ${dockerfile_name} ."

if [[ "$dockerfile_name" == 'Dockerfile-db-temp' ]]; then
	echo; echo "[$scriptName] Clean-up default dockerfile"; echo
	executeExpression "rm -f $dockerfile_name"
fi

echo; echo "[$scriptName] List Resulting images..."
executeExpression "docker images -f label=cdaf.${imageName}.image.version"

echo; echo "[$scriptName] --- end ---"
