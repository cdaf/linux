#!/usr/bin/env bash

# Download to ./automation in current directory
# curl -s https://raw.githubusercontent.com/cdaf/linux/master/provisioning.sh | bash -

# Download specific version and add install directory (/opt/cdaf) to path 
# curl -s https://raw.githubusercontent.com/cdaf/linux/master/provisioning.sh | bash -s -- '2.7.3' '/opt/cdaf'

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
installPath="$1"
if [ -z "$installPath" ]; then
	installPath='./provisioning'
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

executeExpression "cd linux-master/provisioning"
executeExpression "mv * ${installPath}"
executeExpression "cd ../.. && rm -rf linux-master"

if [ ! -z "${CDAF_INSTALL_PATH}" ]; then
    executeExpression "${installPath}/addPath.sh ${installPath}/remote"
    executeExpression "${installPath}/addPath.sh ${installPath}"
fi

echo "[$scriptName] --- end ---"
