#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Directory not supplied, pass as absolute path i.e. /opt/packages. HALT!"
	exit 1
fi

if [ -d "$1" ]; then
	# directory exists, let the calling script decide what to do
	exit 99
else
	# only create the directory if instructed to
	if [ "$2" == "create" ]; then
		echo "$0 : Create $1 on $(hostname)"
		mkdir $1
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo "$0 : Could not create $1 on $(hostname)"
			exit $exitCode
		fi
	fi
fi

