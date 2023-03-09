#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# Deploy script for running on the local host, submission as remote deployment
# managed by calling script.
# The Environment Definition (ENVIR_DEF) is system parameter intended as a validation
# mechanism to ensure this host is in the intended environment (an environment can  
# comprise multiple hosts).

# Check that the environment definition has been passed (this is not the host name)
if [ -z "$1" ]; then
	echo "[$scriptName] Environment Argument not passed. HALT!"
	exit 1
fi

# Change working directory if passed
if [ ! -z "$2" ]; then
	cd $2
fi

# If the environment definition is not set, check from disk
if [ -z "$ENVIR_DEF" ]; then
	ENVIR_DEF=$(cat /etc/environment | grep ENVIR_DEF)
	if [ ! -z "$ENVIR_DEF" ]; then
		echo "[$scriptName] export $ENVIR_DEF from disk"
		eval "export $ENVIR_DEF"
	fi
fi

# Verify that the target environment definition matches that of the host
if [ -z "$ENVIR_DEF" ]; then
	echo "[$scriptName] Environment Undefined, please run setenv.sh utility as elevated user. HALT! $1"
	exit 1
else
	if [ $1 != $ENVIR_DEF ]; then
		echo "[$scriptName] Environment passed, $1 does not match environment definition of this host, $ENVIR_DEF. HALT!"
		exit 1
	fi
fi

# The Version of the current package is contained in a text file (cannot be passed as this maybe run on a remote host)
buildRevision=$(cat ./revision.txt)

echo
echo "[$scriptName] Starting deploy process, logging to $(pwd)/deploy.log"
./deploy.sh "$buildRevision" "$1" 2>&1

echo
echo "[$scriptName] Deployment Complete."
echo
exit 0
