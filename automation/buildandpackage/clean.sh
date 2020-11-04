#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='clean.sh'

echo "[$scriptName] --- start ---"
for argument in "$@"; do
	if [ -z "$i" ]; then
		SOLUTION=${argument}
		echo "[$scriptName]   SOLUTION : ${SOLUTION}"
	else
		echo "[$scriptName]   arg${i}     : ${argument}"
		argument=${argument##*/}     # clean the branch name to
		argument=${argument//\#}     # align with image build
		remoteArray+=( "$argument" )
	fi
	let "i=i+1"
done

echo "[$scriptName] Delete images for inactive branches"; echo
dockerImages=$(docker images --format "{{.Repository}}:{{.ID}}" 2> /dev/null)
for image in $dockerImages; do
	imageSolution=${image%%_*}
	if [[ "${imageSolution}" == "${SOLUTION}" ]]; then
		imageBranch=${image#*_}
		imageBranch=${imageBranch%_*}
		if [[ ! " ${remoteArray[@]} " =~ " ${imageBranch} " ]]; then
			echo "[$scriptName]   docker rmi ${image%:*}"
			docker rmi ${image##*:}
		fi
	fi
done

echo "[$scriptName] --- end ---"
