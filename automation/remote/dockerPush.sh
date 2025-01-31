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

# 2.5.2 Return SHA256 as uppercase Hexadecimal, default algorith is SHA256, but setting explicitely should this change in the future
function MASKED {
	CURRENT_IFS=$IFS
	IFS=$DEFAULT_IFS
	read -ra array <<< $(echo -n $1 | sha256sum)
	echo "${array[0]}" | tr '[:lower:]' '[:upper:]'
	IFS=$CURRENT_IFS
}

scriptName='dockerPush.sh'

echo "[$scriptName] --- start ---"
imageTag=$(echo "$1" | tr '[:upper:]' '[:lower:]') # imageBuild processes in branches as lowercase
if [ -z "$imageTag" ]; then
	echo "[$scriptName] imageTag not supplied!"
	exit 2501
else
	echo "[$scriptName] imageTag        : $imageTag"
fi

registryContext=$2
if [ -z "$registryContext" ]; then
	echo "[$scriptName] registryContext not supplied!"
	exit 2502
else
	echo "[$scriptName] registryContext : $registryContext"
fi

# 2.6.0 Push Private Registry
manifest="${CDAF_CORE}/manifest.txt"
if [ ! -f "$manifest" ]; then
	manifest="${SOLUTIONROOT}/CDAF.solution"
	if [ ! -f "$manifest" ]; then
		echo "[$scriptName] Properties not found in ${CDAF_CORE}/manifest.txt or ${manifest}!"
		exit 5343
	fi
fi

# 2.6.0 CDAF Solution property support, with environment variable override.
registryTags=$3
if [ ! -z "$registryTags" ]; then
    echo "[$scriptName] registryTags    : $registryTags"
else
	if [ ! -z "$CDAF_PUSH_REGISTRY_TAG" ]; then
		registryTags="$CDAF_PUSH_REGISTRY_TAG"
		echo "[$scriptName] registryTags    : $registryTags (loaded from environment variable, supports space separated list)"
	else
		registryTags=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_PUSH_REGISTRY_TAG")")
		if [ ! -z "$registryTags" ]; then
			echo "[$scriptName] registryTags    : $registryTags (loaded from manifest.txt, supports space separated list)"
		else
			registryTags='latest'
			echo "[$scriptName] registryTags    : $registryTags (default, supports space separated list)"
		fi
	fi
fi

registryToken=$4
if [ ! -z "$registryToken" ]; then
	echo "[$scriptName] registryToken   : $(MASKED $registryToken) (MASKED)"
else
	if [ ! -z "$CDAF_PUSH_REGISTRY_TOKEN" ]; then
		registryToken="$CDAF_PUSH_REGISTRY_TOKEN"
		echo "[$scriptName] registryToken   :  $(MASKED ${registryToken}) (loaded from environment variable)"
	else
		registryToken=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_PUSH_REGISTRY_TOKEN")")
		if [ ! -z "$registryToken" ]; then
			echo "[$scriptName] registryToken   :  $(MASKED ${registryToken}) (loaded from manifest.txt)"
		else
			echo "[$scriptName] registryToken   :  (not supplied, login will not be attempted)"
		fi
	fi
fi

registryUser=$5
if [ ! -z "$registryUser" ]; then
	echo "[$scriptName] registryUser    : $registryUser"
else
	if [ ! -z "$CDAF_PUSH_REGISTRY_USER" ]; then
		registryUser="$CDAF_PUSH_REGISTRY_USER"
		echo "[$scriptName] registryUser    : $registryUser (loaded from environment variable)"
	else
		registryUser=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_PUSH_REGISTRY_USER")")
		if [ ! -z "$registryUser" ]; then
			echo "[$scriptName] registryUser    : $registryUser (loaded from manifest.txt)"
		else
			registryUser='.'
			echo "[$scriptName] registryUser    : $registryUser (default)"
		fi
	fi
fi

registryURL=$6
if [ ! -z "$registryURL" ]; then
	echo "[$scriptName] registryURL     : $registryURL"
else
	if [ ! -z "$CDAF_PUSH_REGISTRY_URL" ]; then
		registryURL="$CDAF_PUSH_REGISTRY_URL"
		echo "[$scriptName] registryURL     : $registryURL (loaded from environment variable)"
	else
		registryURL=$(eval "echo $("${CDAF_CORE}/getProperty.sh" "${manifest}" "CDAF_PUSH_REGISTRY_URL")")
		if [ ! -z "$registryURL" ]; then
			echo "[$scriptName] registryURL     : $registryURL (loaded from manifest.txt)"
		else
			echo "[$scriptName] registryURL     : (not supplied, do not set when pushing to Dockerhub, do not include HTTPS:// prefix)"
		fi
	fi
fi

if [ ! -z $registryToken ]; then
	executeExpression "echo \$registryToken | docker login --username $registryUser --password-stdin $registryURL"
fi

# Dockerhub does not require URL to be set, i.e. if URL not supplied, Dockerhub is assumed.
if [ ! -z $registryURL ]; then
	registryContext="${registryURL}/${registryContext}"
fi

for tag in $registryTags; do
	executeExpression "docker tag ${imageTag} ${registryContext}:$tag"
	executeExpression "docker push ${registryContext}:$tag"
done

echo; echo "[$scriptName] --- end ---"
