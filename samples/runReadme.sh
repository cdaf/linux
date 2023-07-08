#!/usr/bin/env bash
scriptName=${0##*/}

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

echo;echo "[$scriptName] --- start ---"
echo "[$scriptName] execute all code blocks in the readme, wrapped in \`\`\`, ignore those using four (4) spaces"; echo
while read LINE
do
	if [[ $LINE == '```' ]]; then
		if [[ $start == 'yes' ]]; then
			start='no'
		else
			start='yes'
		fi 
	else
		if [[ $start == 'yes' ]]; then
			executeExpression "$LINE"
		fi
	fi
	
done < readme.md

echo;echo "[$scriptName] --- end ---"
