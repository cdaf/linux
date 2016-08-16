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
scriptName='installApacheMaven.sh'

echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version='3.3.9'
	echo "[$scriptName]   version   : $version (default)"
else
	echo "[$scriptName]   version   : $version"
fi

mediaPath="$2"
if [ -z "$mediaPath" ]; then
	mediaPath='/vagrant/.provision'
	echo "[$scriptName]   mediaPath : $mediaPath (default)"
else
	echo "[$scriptName]   mediaPath : $mediaPath"
fi

# Set parameters
executeExpression "runTime=\"apache-maven-${version}\""
executeExpression "sourceFile=\"$runTime-bin.tar.gz\""

executeExpression "cp \"$mediaPath/${sourceFile}\" ."
executeExpression "tar -xf $sourceFile"
executeExpression "sudo mv $runTime /opt/"

# Configure to directory on the default PATH
executeExpression "sudo ln -s /opt/$runTime/bin/mvn /usr/bin/mvn"

echo "[$scriptName] Verify install ..."
executeExpression "mvn --version"

echo "[$scriptName] --- end ---"
