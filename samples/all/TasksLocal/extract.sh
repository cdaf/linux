#!/usr/bin/env bash
scriptName=${0##*/}

function executeExpression {
	echo "[$scriptName]   $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

echo
echo "[$scriptName] Extract $1 to $2"

executeExpression "mkdir -p $2/$1"
if [[ "$OSTYPE" == "darwin"* ]]; then # OS/X

	executeExpression "tar -zxvf $2/$1.tar.gz -C $2/$1"

else

	executeExpression "zcat $2/$1.tar.gz | tar -xvf - -C $2/$1"

fi

for script in $(find $2/$1 -name "*.sh"); do 
	chmod +x $script
done
