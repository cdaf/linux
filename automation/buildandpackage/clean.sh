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

echo; echo "[$scriptName] --- start ---"
for argument in "$@"; do
	if [ -z "$i" ]; then
		SOLUTION=${argument}
		echo "[$scriptName]   SOLUTION : ${SOLUTION}"
	else
		echo "[$scriptName]   arg${i}     : ${argument}"
		argument=${argument##*/}                                  # clean the branch name to
		argument=${argument//\#}                                  # align with image build
		argument=$(echo "$argument" | tr '[:upper:]' '[:lower:]') # imageBuild processes in branches as lowercase
		remoteArray+=( "$argument" )
	fi
	let "i=i+1"
done

echo "[$scriptName] Delete ${SOLUTION} images for inactive branches"; echo
for image in $(docker images "${SOLUTION}*" --format "{{.Repository}}:{{.ID}}" 2> /dev/null); do
	imageBranch=${image#*_}       # trim off solution name
	imageBranch=${imageBranch%_*} # trim of image suffix, e.g. containerbuild, test, etc.
	if [[ " ${remoteArray[@]} " =~ " ${imageBranch} " ]]; then
		echo "[$scriptName]   keep ${image%:*}"
	else
		echo "[$scriptName]   docker rmi -f ${image%:*}"
		docker rmi ${image##*:}
	fi
done

echo "[$scriptName] --- end ---"
