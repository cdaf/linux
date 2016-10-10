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

scriptName='dockerLog.sh'
echo
echo "[$scriptName] --- start ---"
imageName=$1
if [ -z "$imageName" ]; then
	echo "[$scriptName] imageName not passed, exiting with code 1."
	exit 1
else
	echo "[$scriptName] imageName   : $imageName"
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

echo
echo "[$scriptName] Monitor log of $imageName for match on \"$stringMatch\"."
echo
# seed or replace the differencing file
: > prevtest.log
for (( c=1; c<=$waitTime; c++ )); do
	test=$(docker logs $imageName | grep "$stringMatch")
	docker logs $imageName > test.log
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

echo
echo "[$scriptName] --- end ---"
