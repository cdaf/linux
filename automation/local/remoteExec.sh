#!/usr/bin/env bash
set -e

# This script provides a repeatable deployment process. This uses two arguments, the target environment
# identifier and the $3 to deploy. Note: each $3 produced is expected to be uniquely identifiable.
echo
if [ -z "$1" ]; then
	echo "$0 deployHost not passed. HALT!"
	exit 1
else
	deployHost=$1
	echo "$0 deployHost    : $deployHost"
fi

if [ -z "$2" ]; then
	echo "$0 deployUser not passed. HALT!"
	exit 2
else
	deployUser=$2
	echo "$0 deployUser    : $deployUser"
fi

if [ -z "$3" ]; then
	echo "$0 deployCommand not passed. HALT!"
	exit 3
else
	deployCommand=$3
	echo "$0 deployCommand : $deployCommand"
fi

if [ -n "$4" ]; then
	arg1=$4
	echo "$0 arg1          : $arg1"
fi

if [ -n "$5" ]; then
	arg2=$5
	echo "$0 arg2          : $arg2"
fi

if [ -n "$6" ]; then
	arg3=$6
	echo "$0 arg3          : $arg3"
fi

if [ -n "$7" ]; then
	arg4=$7
	echo "$0 arg4          : $arg4"
fi

if [ -n "$8" ]; then
	arg5=$8
	echo "$0 arg5          : $arg5"
fi

if [ -n "$9" ]; then
	arg6=$9
	echo "$0 arg6          : $arg6"
fi

if [[ $deployHost == *'$'* ]]; then
	deployHost=$(eval echo $deployHost)
	echo "$0 :   deployHost : $deployHost (evaluated)"
fi
if [[ $deployUser == *'$'* ]]; then
	deployUser=$(eval echo $deployUser)
	echo "$0 :   deployUser : $deployUser (evaluated)"
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
	echo "$0 : Executing command ..."
	echo
	# -n to stop ssh consuming standard in, i.e. when being executed from within execute.sh
	ssh -n -p $deployPort -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $deployUser@$deployHost "$deployCommand $arg1 $arg2 $arg3 $arg4 $arg5 $arg6"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : ssh $deployUser@$deployHost \"$deployCommand $arg1 $arg2 $arg3 $arg4 $arg5 $arg6\" failed! Returned $exitCode"
		exit $exitCode
	fi
else
	echo "$0 : Executing shell script ..."
	echo
	ssh -p $deployPort -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $deployUser@$deployHost 'cat | bash /dev/stdin ' "$arg1 $arg2 $arg3 $arg4 $arg5 $arg6" < $deployCommand 
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : ssh $deployUser@$deployHost \'cat | bash /dev/stdin \' \"$arg1 $arg2 $arg3 $arg4 $arg5 $arg6\" < $deployCommand failed! Returned $exitCode"
		exit $exitCode
	fi
fi