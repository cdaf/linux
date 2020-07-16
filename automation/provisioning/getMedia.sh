#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

scriptName='getMedia.sh'
echo; echo "[$scriptName] ----- Start ------"; echo
if [ -z "$1" ]; then
	echo "[$scriptName] URL not supplied! Exiting with exit code 1."
	exit 1
else
	url="$1"
	echo "[$scriptName]   url         : $url"
fi

if [ -z "$2" ]; then
	mediaCache='/.provision'
	echo "[$scriptName]   mediaCache  : $mediaCache (default)"
else
	mediaCache="$2"
	echo "[$scriptName]   mediaCache  : $mediaCache"
fi

filename=$(echo "${url##*/}")
echo "[$scriptName]   filename    : $filename"

if [ ! -d "$mediaCache" ]; then
	echo "[$scriptName] Create media cache"
	executeExpression "mkdir -v $mediaCache"
	echo
fi

if [ -f "$mediaCache/$filename" ]; then
	echo; echo "[$scriptName] Filename ($mediaCache/$filename) exists in cache, no action attempted, exit normally."; echo
else
	test=$(wget --version 2>/dev/null)
	if [ -z "$test" ]; then
		executeExpression "curl -L --silent $url --output $mediaCache/$filename"
	else
		executeExpression "wget $url --directory-prefix=${mediaCache}"
	fi
fi

echo; echo "[$scriptName] ----- Stop ------"; echo
