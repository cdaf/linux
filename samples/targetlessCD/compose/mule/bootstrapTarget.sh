#!/usr/bin/env bash
function executeExpression {
	counter=1
	max=2
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval $1
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		else
			success='yes'
		fi
	done
}  

scriptName='bootstrapTarget.sh'

echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version='3.8.3'
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

if [ -n "$http_proxy" ]; then
	echo "[$scriptName]   http_proxy : $http_proxy"
	optArg="--proxy $http_proxy"
else
	echo "[$scriptName]   http_proxy : (not set)"
fi

# First check for CDAF in current directory, then check for a Vagrant VM, if not Vagrant
if [ -d './automation/provisioning' ]; then
	atomicPath='.'
else
	echo "[$scriptName] Provisioning directory (./automation/provisioning) not found in workspace, looking for alternative ..."
	if [ -d '/vagrant/automation' ]; then
		atomicPath='/vagrant'
	else
		echo "[$scriptName] /vagrant/automation not found for Vagrant, download from CDAF published site"
		executeExpression "curl -s -O $optArg http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
		executeExpression "tar -xzf LU-CDAF.tar.gz"
		atomicPath='.'
	fi
fi

executeExpression "$atomicPath/automation/provisioning/installOracleJava.sh jre"

installMedia="mule-ee-distribution-standalone-${version}.tar.gz"

if [ ! -d "$mediaCache" ];then
	executeExpression "mkdir $mediaCache"
fi

if [ -f "${installMedia}" ]; then
	echo "[$scriptName] ${mediaCache}/${installMedia} exists, download not required"
else
	executeExpression "curl --silent $optArg https://s3.amazonaws.com/new-mule-artifacts/${installMedia} --output ${mediaCache}/${installMedia}"
fi

executeExpression "tar xf ${mediaCache}/${installMedia}"
if [ -d "${appRoot}/mule-standalone-${version}" ]; then
	executeExpression "rm -rf ${appRoot}/mule-standalone-${version}"
fi

ls -al

executeExpression "$elevate mv -f ./mule-enterprise-standalone-${version} ${appRoot}"
executeExpression "$elevate ln -s ${appRoot}/mule-enterprise-standalone-${version} ${appRoot}/mule"

echo "[$scriptName] Verify install"
echo "/opt/mule/bin/mule status"
/opt/mule/bin/mule status

executeExpression "$atomicPath/automation/remote/capabilities.sh"

echo; echo "[$scriptName] --- end ---"

