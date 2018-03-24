#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='InstallMuleESB.sh'

echo; echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version='3.8.1'
	echo "[$scriptName]   version    : $version (default)"
else
	echo "[$scriptName]   version    : $version"
fi

appRoot="$2"
if [ -z "$appRoot" ]; then
	appRoot='/opt'
	echo "[$scriptName]   appRoot    : $appRoot (default)"
else
	echo "[$scriptName]   appRoot    : $appRoot"
fi

mediaCache="$3"
if [ -z "$mediaCache" ]; then
	mediaCache='/.provision'
	echo "[$scriptName]   mediaCache : $mediaCache (default)"
else
	echo "[$scriptName]   mediaCache : $mediaCache"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

installMedia="mule-standalone-${version}.tar.gz"

if [ ! -d "$mediaCache" ];then
	executeExpression "mkdir $mediaCache"
fi

if [ -f "${installMedia}" ]; then
	echo "[$scriptName] ${mediaCache}/${installMedia} exists, download not required"
else
	executeExpression "curl --silent https://repository.mulesoft.org/nexus/content/repositories/releases/org/mule/distributions/mule-standalone/${version}/${installMedia} --output ${mediaCache}/${installMedia}"
fi

executeExpression "tar xf ${mediaCache}/${installMedia}"
if [ -d "${appRoot}/mule-standalone-${version}" ]; then
	executeExpression "rm -rf ${appRoot}/mule-standalone-${version}"
fi
executeExpression "$elevate mv -f ./mule-standalone-${version} ${appRoot}"
executeExpression "$elevate ln -s ${appRoot}/mule-standalone-${version} ${appRoot}/mule"

echo "[$scriptName] Verify install"
echo "/opt/mule/bin/mule status"
/opt/mule/bin/mule status

echo; echo "[$scriptName] --- end ---"; echo
exit 0