#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# This script provides a repeatable deployment process. This uses two arguments, the target environment
# identifier and the $3 to deploy. Note: each $3 produced is expected to be uniquely identifiable.
echo
if [ -z "$1" ]; then
	echo "$scriptName deployHost not passed. HALT!"
	exit 1
else
	deployHost=$1
	echo "$scriptName deployHost    : $deployHost"
fi

if [ -z "$2" ]; then
	echo "$scriptName deployUser not passed. HALT!"
	exit 2
else
	deployUser=$2
	echo "$scriptName deployUser    : $deployUser"
fi

if [ -z "$3" ]; then
	echo "$scriptName deployCommand not passed. HALT!"
	exit 3
else
	deployCommand=$3
	echo "$scriptName deployCommand : $deployCommand"
fi

if [ ! -z "$4" ]; then
	arg1=$4
	echo "$scriptName arg1          : $arg1"
fi

if [ ! -z "$5" ]; then
	arg2=$5
	echo "$scriptName arg2          : $arg2"
fi

if [ ! -z "$6" ]; then
	arg3=$6
	echo "$scriptName arg3          : $arg3"
fi

if [ ! -z "$7" ]; then
	arg4=$7
	echo "$scriptName arg4          : $arg4"
fi

if [ ! -z "$8" ]; then
	arg5=$8
	echo "$scriptName arg5          : $arg5"
fi

if [ ! -z "$9" ]; then
	arg6=$9
	echo "$scriptName arg6          : $arg6"
fi

if [[ $deployHost == *'$'* ]]; then
	deployHost=$(eval echo $deployHost)
	echo "[$scriptName]   deployHost : $deployHost (evaluated)"
fi
if [[ $deployUser == *'$'* ]]; then
	deployUser=$(eval echo $deployUser)
	echo "[$scriptName]   deployUser : $deployUser (evaluated)"
fi

# Process the deployHost, stripping out the port if passed, i.e. localhost:2222
sep=':'
case $deployHost in
	(*"$sep"*)
    	    deployPort=${deployHost#*"$sep"}
			deployHost=${deployHost%%"$sep"*}
    	    ;;
		(*)
    	    userHost=$deployHost
    	    deployPort="22"
    ;;
esac

echo
# If a command is passed, then just execute, is command is a local script, execute that script on the remote target
extension="${deployCommand##*.}"
if [ "$extension" != 'sh' ]; then
	echo "[$scriptName] Executing command ..."
	echo
	# -n to stop ssh consuming standard in, i.e. when being executed from within execute.sh
	ssh -n -p $deployPort -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $deployUser@$deployHost "$deployCommand $arg1 $arg2 $arg3 $arg4 $arg5 $arg6"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] ssh $deployUser@$deployHost \"$deployCommand $arg1 $arg2 $arg3 $arg4 $arg5 $arg6\" failed! Returned $exitCode"
		exit $exitCode
	fi
else
	echo "[$scriptName] Executing shell script ..."
	echo
	ssh -p $deployPort -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $deployUser@$deployHost 'cat | bash /dev/stdin ' "$arg1 $arg2 $arg3 $arg4 $arg5 $arg6" < $deployCommand 
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] ssh $deployUser@$deployHost \'cat | bash /dev/stdin \' \"$arg1 $arg2 $arg3 $arg4 $arg5 $arg6\" < $deployCommand failed! Returned $exitCode"
		exit $exitCode
	fi
fi