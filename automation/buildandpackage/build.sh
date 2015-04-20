#!/usr/bin/env bash
set -e

# THIS FILE IS A EXAMPLE AND NOT USED, copy to each project in project.list file
# Project Build Script, this maybe use ant, maven or simple scripts to create the build artefacts

if [ -z "$1" ]; then
	echo "$0 : Project not passed!"
	exit 1
else
	PROJECT="$1"
fi

if [ -z "$2" ]; then
	echo "$0 : Build Number not passed!"
	exit 1
else
	BUILDNUMBER="$2"
fi

if [ -z "$3" ]; then
	echo "$0 : Revision not passed!"
	exit 1
else
	REVISION="$3"
fi

if [ ! -z "$4" ]; then
	ACTION="$4"
fi

if [ "$ACTION" == "clean" ]; then
	echo "$0 : $PROJECT Clean only, using ant"
	echo
	ant clean
else
	echo "$0 : Build $PROJECT using ant"
	echo "$0 :   BUILDNUMBER : $BUILDNUMBER"
	echo "$0 :   REVISION    : $REVISION"
	echo "$0 :   pwd         : $(pwd)"
	echo
	ant -DbuildRevision="$BUILDNUMBER-$REVISION" -Dproject.name="$(basename $(pwd))"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$0 : Building Failed, exit code = $exitCode."
		exit $exitCode
	fi
fi
