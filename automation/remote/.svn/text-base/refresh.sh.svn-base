#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Version not supplied. HALT!"
	exit 1
else
	VERSION=$1
fi

if [ -z "$2" ]; then
	echo "$0 : Environment not supplied. HALT!"
	exit 2
else
	ENVIRONMENT=$2
fi

if [ -z "$3" ]; then
	echo "$0 : Target not supplied. HALT!"
	exit 3
else
	TARGET=$3
fi

if [ -z "$4" ]; then
	echo "$0 : Target Path not supplied. HALT!"
	exit 4
else
	PATHPROPERTY=$4
fi

if [ -z "$5" ]; then
	echo "$0 : Target not supplied. HALT!"
	exit 5
else
	SOURCEPACKAGE=$5
fi

targetPath=$(./getProperty.sh "../$TARGET" "$PATHPROPERTY")
if [ -z "$PATHPROPERTY" ]; then
	echo "$0 : Unable to retrieve targetPath value from ../$TARGET for path property $PATHPROPERTY! Returning exit 99"
	exit 99
fi

echo
echo "$0 : Remove current content, before and after to verify ..."
echo
echo "$0 : ------------------ before ---------------------------"
echo
ls -l $targetPath/
echo 
echo "$0 : ------------------ before ---------------------------"
echo 
echo "$0 : rm -rf $targetPath/*"
rm -rf $targetPath/*
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Unable to clear content! Returned $exitCode"
	exit $exitCode
fi
echo
echo "$0 : ------------------ after ----------------------------"
echo
ls -l $targetPath/
echo
echo "$0 : ------------------ after ----------------------------"
echo

echo "$0 : Extract new content"
unzip $SOURCEPACKAGE -d $targetPath
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Unable to extract content! Returned $exitCode"
	exit $exitCode
fi
