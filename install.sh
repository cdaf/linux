#!/usr/bin/env bash

# Download to named directory and add to path, without this, will simply download and extract in current directory
# export CDAF_INSTALL_PATH=/opt/cdaf
# curl -s https://raw.githubusercontent.com/cdaf/linux/master/install.sh | bash -

function executeExpression {
	echo "$1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][ERROR] $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='install.sh'

echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	echo "[$scriptName]   version           : (not passed, use edge)"
else
	echo "[$scriptName]   version           : $version"
fi

if [ -z "$CDAF_INSTALL_PATH" ]; then
	installPath='./automation'
	echo "[$scriptName]   installPath       : $installPath (default)"
else
	installPath="$CDAF_INSTALL_PATH"
	echo "[$scriptName]   installPath       : $installPath (from CDAF_INSTALL_PATH)"
fi

if [ -d "${installPath}" ]; then
	executeExpression "rm -rf '${installPath}'"
fi

parentdir="$(dirname "${installPath}")"
if [ ! -d "${parentdir}" ]; then
	executeExpression "mkdir -p '${parentdir}'"
fi

if [ -z "$version" ]; then
	unzip &>/dev/null
	if [ $? -ne 0 ]; then
		executeExpression "curl -s https://raw.githubusercontent.com/cdaf/linux/master/automation/provisioning/base.sh | bash -" # default package is unzip
	fi
	executeExpression "curl -s https://codeload.github.com/cdaf/linux/zip/master --output linux-master.zip"
	executeExpression "unzip -o linux-master.zip"
	executeExpression "rm linux-master.zip"
	
	executeExpression "mv ./linux-master/automation ${installPath}"
	executeExpression "rm -rf linux-master"
else
	executeExpression "curl -s http://cdaf.io/static/app/downloads/LU-CDAF-${version}.tar.gz | tar -xz"
	if [[ installPath != './automation' ]]; then
		executeExpression "mv ./automation ${installPath}"
	fi
fi

if [ ! -z "${CDAF_INSTALL_PATH}" ]; then
	executeExpression "${installPath}/provisioning/addPath.sh ${installPath}/provisioning"
	executeExpression "${installPath}/provisioning/addPath.sh ${installPath}/remote"
	executeExpression "${installPath}/provisioning/addPath.sh ${installPath}"
fi

executeExpression "${installPath}/remote/capabilities.sh"

echo "[$scriptName] --- end ---"
