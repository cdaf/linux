#!/usr/bin/env bash
scriptName=${0##*/}

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$scriptName : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='logWatch.sh'
echo
echo "[$scriptName] --- start ---"
logFile=$1
if [ -z "$logFile" ]; then
	echo "[$scriptName] logFile not passed, exiting with code 110."
	exit 110
else
	echo "[$scriptName] logFile     : $logFile"
fi

stringMatch=$2
if [ -z "$stringMatch" ]; then
	echo "[$scriptName] stringMatch not passed, exiting with code 120."
	exit 120
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

echo ; echo "[$scriptName] Monitor log file $logFile for match on \"$stringMatch\"." ; echo

wait=5
retryMax=$((waitTime / wait))
retryCount=0
lastLineNumber=0
exitCode=4366
while [ $retryCount -le $retryMax ] && [ $exitCode -ne 0 ]; do
	sleep $wait
	output=$(cat $logFile)
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
	
		found=$(echo $output | grep "$stringMatch")
	    if [ ! -z "$found" ]; then
			echo "[$scriptName] stringMatch ($stringMatch) found."
		    exitCode=0
		fi
	fi

	if [ $retryCount -ge $retryMax ]; then
		echo "[$scriptName] Retry maximum ($retryMax) reached, exiting with code 334"
		exitCode=335
	fi
	let "retryCount=retryCount+1"
done

echo; echo "[$scriptName] --- end ---"
