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
	version='3.5.0'
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

# Check for media
echo
mediaFullPath="$mediaPath/apache-maven-${version}-bin.tar.gz"
echo "[$scriptName] \$mediaFullPath = $mediaFullPath"
if [ -f "$mediaFullPath" ]; then
	echo "[$scriptName] Media found $mediaFullPath"
else
	echo "[$scriptName] Media not found, attempting download"
	if [ ! -d "$mediaPath" ]; then
		executeExpression "sudo mkdir -p $mediaPath"
	fi
	executeExpression "sudo curl -s -o $mediaFullPath http://www-eu.apache.org/dist/maven/maven-3/${version}/binaries/apache-maven-${version}-bin.tar.gz"
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
