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

echo; echo "--- Test all Samples ---"

dirlist=$(find . -maxdepth 1 -type d -not -path "." | sort)

echo
for dirname in $dirlist; do
	echo;echo "---------------------"
	echo "   $dirname"
	echo "---------------------"; echo
	executeExpression "cd $dirname"
	executeExpression "../../automation/cdEmulate.sh"
	executeExpression "cd .."
	echo
done

echo "Sample test complete for:"
echo $dirlist

echo; echo "--- Completed Samples Test ---"
