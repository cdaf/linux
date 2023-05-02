#!/usr/bin/env bash
scriptName=${0##*/}

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

echo
echo "[$scriptName] --- start ---"
container=$1
if [ -z "$container" ]; then
	echo "[$scriptName] container not passed, exiting with code 1."
	exit 1
else
	echo "[$scriptName] container   : $container"
fi

stringMatch=$2
if [ -z "$stringMatch" ]; then
	echo "[$scriptName] stringMatch not passed, exiting with code 2."
	exit 2
else
	echo "[$scriptName] stringMatch : $stringMatch"
fi

waitTime=$3
if [ -z "$waitTime" ]; then
	waitTime=60
	echo "[$scriptName] waitTime    : $waitTime (seconds, default)"
else
	echo "[$scriptName] waitTime    : $waitTime (seconds)"
fi

exactMatch=$4
if [ -z "$exactMatch" ]; then
	exactMatch="CONTAINS"
	echo "[$scriptName] exactMatch  : $exactMatch (default)"
else
	echo "[$scriptName] exactMatch  : $exactMatch"
fi

trim=$5
if [ -z "$trim" ]; then
	trim="NO_TRIM"
	echo "[$scriptName] trim        : $trim (default)"
else
	echo "[$scriptName] trim        : $trim"
fi

echo
echo "[$scriptName] Monitor log of $container for match on \"$stringMatch\"."
echo

wait=5
retryMax=$((waitTime / wait))
retryCount=0
lastLineNumber=0
exitCode=4366
while [ $retryCount -le $retryMax ] && [ $exitCode -ne 0 ]; do
	sleep $wait
	if [[ "$container" == 'DOCKER-COMPOSE' ]]; then
		output=$(docker-compose logs --no-color 2>&1)
	else
		output=$(docker logs $container 2>&1)
	fi
	if [ -z "$output" ]; then
		echo "[$scriptName]   no output ..."
    else
		lineCount=1
		while read -r line; do
	    	if [ $lineCount -gt $lastLineNumber ]; then
				echo "> $line"
				lastLineNumber=$lineCount
			fi
			let "lineCount=lineCount+1"
		done < <(echo "$output")

		found=$(echo $output | grep "CDAF_DELIVERY_FAILURE.")
	    if [ ! -z "$found" ]; then
			echo "[$scriptName] CDAF_DELIVERY_FAILURE. detected, exiting with code 8335. Wait time was ${waitTime}."
		    exitCode=8335
		    retryCount=$retryMax
		else
			if [ "$exactMatch" == "EXACT" ]; then
				readarray -t outputLines <<< "$output"
				for line in "${outputLines[@]}"; do
					if [ "$trim" == "TRIM" ]; then
						line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
					fi
					if [ "$line" == "$stringMatch" ]; then
						echo "[$scriptName] exact stringMatch ($stringMatch) found."
						exitCode=0
						break
					fi
				done
			else
				found=$(echo $output | grep "$stringMatch")
		    	if [ ! -z "$found" ]; then
					echo "[$scriptName] stringMatch ($stringMatch) found."
			   	exitCode=0
				fi
			fi
		fi
	fi

	if [ $retryCount -ge $retryMax ]; then
		echo "[$scriptName] Maximum wait time ($waitTime) reached after $retryMax retries, exiting with code $waitTime (waitTime)"
		exitCode=$waitTime
	fi
	let "retryCount=retryCount+1"
done

echo
echo "[$scriptName] --- end ---"
exit $exitCode
