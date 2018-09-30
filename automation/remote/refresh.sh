#!/usr/bin/env bash
set -e
scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "$scriptName : Version not supplied. HALT!"
	exit 1
else
	VERSION=$1
fi

if [ -z "$2" ]; then
	echo "$scriptName : Environment not supplied. HALT!"
	exit 2
else
	ENVIRONMENT=$2
fi

if [ -z "$3" ]; then
	echo "$scriptName : Target not supplied. HALT!"
	exit 3
else
	TARGET=$3
fi

if [ -z "$4" ]; then
	echo "$scriptName : Target Path not supplied. HALT!"
	exit 4
else
	PATHPROPERTY=$4
fi

if [ -z "$5" ]; then
	echo "$scriptName : Target not supplied. HALT!"
	exit 5
else
	SOURCEPACKAGE=$5
fi

targetPath=$(./getProperty.sh "./$TARGET" "$PATHPROPERTY")
if [ -z "$PATHPROPERTY" ]; then
	echo "$scriptName : Unable to retrieve targetPath value from ./$TARGET for path property $PATHPROPERTY! Returning exit 99"
	exit 99
fi

echo
echo "$scriptName : Remove current content, before and after to verify ..."
echo
echo "$scriptName : ------------------ before ---------------------------"
echo
ls -l $targetPath/
echo 
echo "$scriptName : ------------------ before ---------------------------"
echo 
echo "$scriptName : rm -rf $targetPath/*"
rm -rf $targetPath/*
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Unable to clear content! Returned $exitCode"
	exit $exitCode
fi
echo
echo "$scriptName : ------------------ after ----------------------------"
echo
ls -l $targetPath/
echo
echo "$scriptName : ------------------ after ----------------------------"
echo

echo "$scriptName : Extract new content"
./extract.sh  $SOURCEPACKAGE $targetPath
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$scriptName : Unable to extract content! Returned $exitCode"
	exit $exitCode
fi
