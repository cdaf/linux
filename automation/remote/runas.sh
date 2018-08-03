#!/usr/bin/env bash
scriptName='runas.sh'

echo "[$scriptName] --- start ---"
runAsUser="$1"
if [ -z "$runAsUser" ]; then
	echo "[$scriptName]   runAsUser not supplied!"; exit 110
else
	echo "[$scriptName]   runAsUser : $runAsUser"
fi

command="$2"
if [ -z "$command" ]; then
	echo "[$scriptName]   command not supplied!"; exit 120
else
	echo "[$scriptName]   command   : $command"
fi

(
su ${runAsUser} << EOC

	eval $command
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ ! -z "$exitCode" ] && [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi

EOC
)
exitCode=$?
# Check execution normal, anything other than 0 is an exception
if [ ! -z "$exitCode" ] && [ "$exitCode" != "0" ]; then
	echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
	exit $exitCode
fi

echo "[$scriptName] --- end ---"
