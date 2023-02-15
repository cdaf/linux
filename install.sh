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
	echo "[$scriptName]   version           : (not passed, use edge from GitHub)"
else
	echo "[$scriptName]   version           : $version (use published version from cdaf.io)"
fi

if [ -z "$CDAF_INSTALL_PATH" ]; then
	installPath='./automation'
	echo "[$scriptName]   installPath       : $installPath (default)"
else
	installPath="$CDAF_INSTALL_PATH"
	echo "[$scriptName]   installPath       : $installPath (from CDAF_INSTALL_PATH)"
fi

if [ -d "${installPath}" ]; then
	executeExpression "find \"${installPath}\" -mindepth 1 -delete"
else
	executeExpression "mkdir -p \"${installPath}\""
fi

# Convert to absolute path
installPath=$(echo "$(cd "$(dirname "$installPath")"; pwd)/$(basename "$installPath")")

if [ -z "$version" ]; then
	test="`unzip 2>&1`"
	if [ $? -ne 0 ]; then
		echo "unzip, not installed, installing"
		executeExpression "curl -s https://raw.githubusercontent.com/cdaf/linux/master/automation/provisioning/base.sh | bash -" # default package is unzip
		test="`unzip --version 2>&1`"
		if [ $? -ne 0 ]; then
			echo "Could not install unzip!"; exit 4624
		else
			IFS=' ' read -ra ADDR <<< $test
			test=${ADDR[1]}
			echo "  unzip             : $test"
		fi	
	else
		IFS=' ' read -ra ADDR <<< $test
		test=${ADDR[1]}
		echo "  unzip             : $test"
	fi	
	executeExpression "curl -s https://codeload.github.com/cdaf/linux/zip/master --output linux-master.zip"
	executeExpression "unzip -o linux-master.zip"
	executeExpression "rm linux-master.zip"

	executeExpression "cd linux-master/automation"
	executeExpression "mv * ${installPath}"
	executeExpression "cd ../.. && rm -rf linux-master"
else
	executeExpression "curl -s http://cdaf.io/static/app/downloads/LU-CDAF-${version}.tar.gz | tar -xz"
	if [ -z "$CDAF_INSTALL_PATH" ]; then
		executeExpression "cd automation"
		executeExpression "mv * ${installPath}"
		executeExpression "cd .. && rm -rf automation"
	fi
fi

if [ ! -z "${CDAF_INSTALL_PATH}" ]; then
	executeExpression "${installPath}/provisioning/addPath.sh ${installPath}/provisioning"
	executeExpression "${installPath}/provisioning/addPath.sh ${installPath}/remote"
	executeExpression "${installPath}/provisioning/addPath.sh ${installPath}"
fi

echo "${installPath}/remote/capabilities.sh"
eval "${installPath}/remote/capabilities.sh"
exitCode=$?
# Check execution normal, anything other than 0 is an exception
if [ "$exitCode" != "0" ]; then
	echo "[$scriptName][ERROR] $EXECUTABLESCRIPT returned $exitCode, list install directory contents and exit..."
	ls -al -R
	exit $exitCode
fi

echo "[$scriptName] --- end ---"
