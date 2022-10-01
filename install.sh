#!/usr/bin/env bash
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
	echo "[$scriptName]   version : (not passed, use edge)"
else
	echo "[$scriptName]   version : $version"
fi

if [ -z "$version" ]; then
	executeExpression "curl -s -O https://raw.githubusercontent.com/cdaf/linux/master/automation/provisioning/base.sh"
	executeExpression "chmod +x base.sh"
	executeExpression "rm base.sh"
	executeExpression "./base.sh unzip"
	executeExpression "curl -s https://codeload.github.com/cdaf/linux/zip/master --output linux-master.zip"
	executeExpression "unzip -o linux-master.zip"
	executeExpression "rm linux-master.zip"
	executeExpression "mv ./linux-master/ ./automation/"
else
	executeExpression " curl -s http://cdaf.io/static/app/downloads/LU-CDAF-${version}.tar.gz | tar -xz"
fi

executeExpression "./automation/remote/capabilities.sh"

echo "[$scriptName] --- end ---"
