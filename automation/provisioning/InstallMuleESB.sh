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

scriptName='InstallMuleESB.sh'

echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version='3.8.1'
	echo "[$scriptName]   version : $version (default)"
else
	echo "[$scriptName]   version : $version"
fi

appRoot="$2"
if [ -z "$appRoot" ]; then
	appRoot='/opt'
	echo "[$scriptName]   appRoot : $appRoot (default)"
else
	echo "[$scriptName]   appRoot : $appRoot"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami  : $(whoami)"
else
	echo "[$scriptName]   whoami  : $(whoami) (elevation not required)"
fi

executeExpression "curl -O https://repository.mulesoft.org/nexus/content/repositories/releases/org/mule/distributions/mule-standalone/${version}/mule-standalone-${version}.tar.gz"
executeExpression "tar xf mule-standalone-${version}.tar.gz"
executeExpression "$elevate mv -f ./mule-standalone-${version} ${appRoot}"
executeExpression "$elevate ln -s ${appRoot}/mule-standalone-${version} ${appRoot}/mule"

echo "[$scriptName] --- end ---"
