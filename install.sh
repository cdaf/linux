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
	CDAF_INSTALL_PATH='./automation'
	echo "[$scriptName]   CDAF_INSTALL_PATH : ${CDAF_INSTALL_PATH} (default)"
else
	echo "[$scriptName]   CDAF_INSTALL_PATH : ${CDAF_INSTALL_PATH}"
fi

if [ -z "$version" ]; then
	executeExpression "curl -s https://raw.githubusercontent.com/cdaf/linux/master/automation/provisioning/base.sh | bash -" # default package in unzip
	executeExpression "curl -s https://codeload.github.com/cdaf/linux/zip/master --output linux-master.zip"
	executeExpression "unzip -o linux-master.zip"
	executeExpression "rm linux-master.zip"
	executeExpression "mv ./linux-master/automation ${CDAF_INSTALL_PATH}"
	executeExpression "rm -rf linux-master"	
else
	executeExpression " curl -s http://cdaf.io/static/app/downloads/LU-CDAF-${version}.tar.gz | tar -xz"
fi

if [ ! -z "${CDAF_INSTALL_PATH}" ]; then
	executeExpression "${CDAF_INSTALL_PATH}/provisioning/addPath.sh ${CDAF_INSTALL_PATH}/provisioning"
	executeExpression "${CDAF_INSTALL_PATH}/provisioning/addPath.sh ${CDAF_INSTALL_PATH}/remote"
	executeExpression "${CDAF_INSTALL_PATH}/provisioning/addPath.sh ${CDAF_INSTALL_PATH}"
fi

executeExpression "${CDAF_INSTALL_PATH}/remote/capabilities.sh"

echo "[$scriptName] --- end ---"
