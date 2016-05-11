#!/usr/bin/env bash
scriptName='npm.sh'

# Trivial wrapper to provide consistent invocation in Vagrant and Docker
echo "[$scriptName] --- start ---"
module=$1
if [ "$module" ]; then
	echo "[$scriptName]   module     : $module (use @version if required)"
else
	echo "[$scriptName]   module not supplied, exiting"
	exit 1
fi

# Install from global repositories only supporting CentOS and Ubuntu
npmVersion=$(npm -version 2> /dev/null)
if [ "$npmVersion" ]; then
	echo "[$scriptName]   npmVersion : $npmVersion"
else
	echo "[$scriptName]   npm not installed, install using node.sh"
	exit 2
fi

npm install $module
 
echo "[$scriptName] --- end ---"
