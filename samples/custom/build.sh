#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $1 returned $exitCode"
		exit $exitCode
	fi
}

scriptName='build.sh'

echo;echo "[$scriptName] --- start ---"
SOLUTION=$1
if [ -z "$SOLUTION" ]; then
	echo "[$scriptName] SOLUTION not supplied, exit with code 1."
	exit 1
else
	echo "[$scriptName] SOLUTION      : $SOLUTION"
fi

BUILDNUMBER=$2
if [ -z "$BUILDNUMBER" ]; then
	echo "[$scriptName] BUILDNUMBER not supplied, exit with code 2."
	exit 2
else
	echo "[$scriptName] BUILDNUMBER   : $BUILDNUMBER"
fi

REVISION=$3
if [ -z "$REVISION" ]; then
	echo "[$scriptName] REVISION      : (not supplied)"
else
	echo "[$scriptName] REVISION      : $REVISION"
fi

ACTION=$4
if [ -z "$ACTION" ]; then
	echo "[$scriptName] ACTION        : (not supplied)"
else
	echo "[$scriptName] ACTION        : $ACTION"
fi

echo; echo 'Disadvantage of a custom script is that the default variables, e.g. $AUTOMATIONROOT & $SOLUTIONROOT are not loaded,'
echo 'Consider calling a custom script from a build.tsk and pass these as variables.'
echo; echo 'Use executeExpression to replicate the build.tsk logging and exception handling'

executeExpression 'echo "#!/usr/bin/env bash" > binary.sh'
executeExpression 'echo "echo" >> binary.sh'
executeExpression 'echo "echo [binary.sh] Created by custom build script" >> binary.sh'
executeExpression 'chmod +x binary.sh'
executeExpression './binary.sh'

echo; echo "[$scriptName] --- end ---"; echo
