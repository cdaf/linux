#!/usr/bin/env bash
set -e

scriptName="remotePackageManagement.sh (remote)"

if [ -z "$1" ]; then
	echo
	echo "$scriptName : Directory not supplied, pass as absolute path e.g. /opt/packages. HALT!"
	exit 1
else
	LANDING_DIR=$1
fi

if [ -z "$2" ]; then
	echo
	echo "$scriptName : Package Name not supplied e.g. package-10. HALT!"
	exit 2
else
	PACKAGE_NAME=$2
fi

# If this script has started, then the SSH session is valid
echo "$scriptName : Connection test Successful"

if [ ! -d "$LANDING_DIR" ]; then
	echo "$scriptName : Target path does not exist, attempt to create $LANDING_DIR"
	mkdir -pv $1
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$scriptName : Could not create $LANDING on $(hostname)"
		exit $exitCode
	fi
fi

timeStamp=$(date "+%Y%m%d_%T")

if [ -f "$LANDING_DIR/$PACKAGE_NAME.zip" ]; then
	echo
	echo "$scriptName : Package file ($LANDING_DIR/$PACKAGE_NAME.zip) exists rename:"
	newPackage="$PACKAGE_NAME"
	newPackage+="-$timeStamp.zip"
	mv -v $LANDING_DIR/$PACKAGE_NAME.zip $LANDING_DIR/$newPackage
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$scriptName : Could not move existing package to $LANDING_DIR/$newPackage on $(hostname)"
		exit $exitCode
	fi
fi

if [ -d "$LANDING_DIR/$PACKAGE_NAME" ]; then
	echo
	echo "$scriptName : Extracted package directory ($LANDING_DIR/$PACKAGE_NAME) exists rename:"
	newPackage="$PACKAGE_NAME"
	newPackage+="-$timeStamp"
	mv -v $LANDING_DIR/$PACKAGE_NAME $LANDING_DIR/$newPackage
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$scriptName : Could not move existing extracted package to $LANDING_DIR/$newPackage on $(hostname)"
		exit $exitCode
	fi
fi