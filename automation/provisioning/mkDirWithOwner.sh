#!/usr/bin/env bash
scriptName='mkDir.sh'
echo
echo "[$scriptName] Create a directory (full path supported) and set a group owner (optional)"
echo
if [ -z "$1" ]; then
	echo "[$scriptName]   directory no supplied!"
	exit 1
else
	directory="$1"
	echo "[$scriptName]   directory : $directory"
fi

if [ -z "$2" ]; then
	echo "[$scriptName]   user      : not supplied"
else
	user="$2"
	echo "[$scriptName]   user      : $user"
fi

if [ -z "$3" ]; then
	echo "[$scriptName]   group     : not supplied"
else
	group="$3"
	echo "[$scriptName]   group     : $group"
fi

echo "[$scriptName] Create directory if it does not exist"
if [ -d "$directory" ]; then
	echo "[$scriptName] Landing directory ($directory) exists"
else
	echo "[$scriptName] Create landing directory, $directory"
	sudo mkdir -p "$directory"
fi

# Only attempt to set ownership if user has been supplied.
if [ "$user" ]; then
	if [ -z "$group" ]; then
		echo "[$scriptName] sudo chown $user $directory"
		sudo chown $user "$directory"
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] Unable to set ownership, does user exist? Exiting with exit code $exitCode"
			exit $exitCode
		fi
	else
		echo "[$scriptName] sudo chown $user:$group $directory"
		sudo chown $user:$group "$directory"
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] Unable to set ownership, does ($user) user and group ($group) exist? Exiting with exit code $exitCode"
			exit $exitCode
		fi
	fi
fi

echo "[$scriptName] --- end ---"
