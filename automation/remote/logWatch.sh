#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
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

echo
echo "[$scriptName] Monitor log of $logFile for match on \"$stringMatch\"."
echo
# seed or replace the differencing file
: > prevtest.log
for (( c=1; c<=$waitTime; c++ )); do
	cat $logFile > test.log
	test=$(cat test.log | grep "$stringMatch")
	diff test.log prevtest.log
	mv test.log prevtest.log
	if [ -z "$test" ]; then
		sleep 1
	else
		echo "[$scriptName] \"$stringMatch\" found."
		c=$waitTime
	fi
done

if [ -z "$test" ]; then
	echo "[$scriptName] \'$stringMatch\' not found! Exiting with code 99"
	exit 99
fi

sleep 2

echo; echo "[$scriptName] --- end ---"
