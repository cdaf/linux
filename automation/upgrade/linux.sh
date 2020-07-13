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

echo "[$scriptName] --- start ---"

zipFile='LU-CDAF.tar.gz'
url="http://cdaf.io/static/app/downloads/$zipFile"
extract='/tmp/LU-CDAF'
if [ -d $extract ]; then
	executeExpression "rm -rf $extract"
fi
executeExpression "mkdir $extract"

executeExpression "curl -s --output ${extract}/${zipFile} $url"
executeExpression "tar -C $extract -xf ${extract}/${zipFile}"
 
executeExpression 'rm -rf ./automation/'
executeExpression 'cp -r $extract/automation .'

git branch
if [ $? -eq 0 ]; then
	executeExpression 'cd automation'
	executeExpression 'for file in $(find .); do git add --ignore-removal $file; done'
	executeExpression 'for script in $(find . -name "*.sh"); do chmod +x $script; git update-index --chmod=+x $script; done'
	executeExpression 'cd ..'
else
	svn ls
	if [ $? -eq 0 ]; then
	executeExpression 'for file in $(find .); do svn add $file --force; done'
		executeExpression 'for script in $(find . -name "*.sh"); svn propset svn:executable ON -R $script; done'
	fi
fi

echo "[$scriptName] --- end ---"
