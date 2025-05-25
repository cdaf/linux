#!/usr/bin/env bash

# Download to ./automation in current directory
# curl -s https://raw.githubusercontent.com/cdaf/linux/master/install.sh | bash -

# Download specific version and add install directory (/opt/cdaf) to path 
# curl -s https://raw.githubusercontent.com/cdaf/linux/master/install.sh | bash -s -- '2.7.3' '/opt/cdaf'

# Optional environment variables, alternative to downloading and passing arguments.
# export CDAF_INSTALL_VERSION = '2.7.3'
# export CDAF_INSTALL_PATH=/opt/cdaf

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
	if [ -z "$CDAF_INSTALL_VERSION" ]; then
		echo "[$scriptName]   version           : (not passed, use edge from GitHub)"
	else
		if [[ "$CDAF_INSTALL_VERSION" == 'Edge' ]]; then
			echo "[$scriptName]   version           : (using edge from GitHub based on CDAF_INSTALL_VERSION)"
		else
			version="$CDAF_INSTALL_VERSION"
			echo "[$scriptName]   version           : $version (based on CDAF_INSTALL_VERSION)"
		fi
	fi
else
	echo "[$scriptName]   version           : $version (use published version from cdaf.io)"
fi

installPath="$2"
if [ -z "$installPath" ]; then
	if [ -z "$CDAF_INSTALL_PATH" ]; then
		installPath='./automation'
		echo "[$scriptName]   installPath       : $installPath (default)"
	else
		installPath="$CDAF_INSTALL_PATH"
		echo "[$scriptName]   installPath       : $installPath (from CDAF_INSTALL_PATH)"
	fi
else
	CDAF_INSTALL_PATH="$installPath"
	echo "[$scriptName]   installPath       : $installPath (install and add to PATH)"
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
		executeExpression "curl -s https://raw.githubusercontent.com/cdaf/linux/master/provisioning/base.sh | bash -" # default package is unzip
		test="`unzip 2>&1`"
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
	if [ -d "automation" ]; then
		executeExpression "rm -rf automation"
	fi
	executeExpression "curl -s https://cdaf.io/static/app/downloads/LU-CDAF-${version}.tar.gz | tar -xz"
	if [ ! -z "$CDAF_INSTALL_PATH" ]; then
		executeExpression "cd automation"
		executeExpression "mv * ${installPath}"
		executeExpression "cd .. && rm -rf automation"
	fi
fi

if [ ! -z "${CDAF_INSTALL_PATH}" ]; then
    executeExpression "curl -s -f https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/addPath.sh -o ${installPath}/addPath.sh"
    executeExpression "chmod +x ${installPath}/addPath.sh"
    executeExpression "${installPath}/addPath.sh ${installPath}/remote"
    executeExpression "${installPath}/addPath.sh ${installPath}"
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
