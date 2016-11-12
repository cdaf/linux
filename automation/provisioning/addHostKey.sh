#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  
scriptName='addHostKey.sh'

echo "[$scriptName] --- start ---"
userTarget="$1"
if [ -z "$userTarget" ]; then
	echo "User and target not supplied, in user@host format!"; 	exit 1
else
	echo "[$scriptName]   userTarget : $userTarget"
fi

runas="$2"
if [ -z "$runas" ]; then
	echo "[$scriptName]   runas      : (not supplied, run as current user)"
else
	echo "[$scriptName]   runas      : $runas"
fi

echo "[$scriptName]   whoami     : $(whoami)"
echo

# If a runas user is supplied, execute as them
if [ -n "$runas" ]; then
	executeExpression "sudo -u $runas ssh -o StrictHostKeyChecking=no $userTarget 'echo \"Confirmed user \$(whoami) on host \$(hostname -f)\"' "
else
	executeExpression "ssh -o StrictHostKeyChecking=no $userTarget 'echo \"Confirmed user \$(whoami) on host \$(hostname -f)\"' "
fi

echo "[$scriptName] --- end ---"
