#!/usr/bin/env bash
scriptName=${0##*/}

echo "[$scriptName] --- start ---"
wait="$2"
if [ -z "$wait" ]; then
	wait=10
	echo "[$scriptName]   wait      : $wait (default, seconds)"
else
	echo "[$scriptName]   wait      : $wait (seconds)"
fi

retryMax="$3"
if [ -z "$retryMax" ]; then
	retryMax=5
	echo "[$scriptName]   retryMax  : $retryMax (default)"
else
	echo "[$scriptName]   retryMax  : $retryMax"
fi

counter=1
success='no'
while [ "$success" != 'yes' ]; do
	echo "[$scriptName][$counter] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		counter=$((counter + 1))
		if [ "$counter" -le "$retryMax" ]; then
			echo "[$scriptName] Failed with exit code ${exitCode}! Wait $wait seconds, then retry $counter of ${retryMax}"
			sleep $wait
		else
			echo "[$scriptName] Failed with exit code ${exitCode}! Maximum retries (${retryMax}) reached."
			exit $exitCode
		fi					 
	else
		success='yes'
	fi
done
	
echo "[$scriptName] --- stop ---"
exit 0
