#!/usr/bin/env bash
# Consolidated Error processing function
#  required : error message
#  optional : exit code, if not supplied only error message is written
function ERRMSG {
	if [ -z "$2" ]; then
		echo; echo "[$scriptName][ERRMSG][WARN] $1"
	else
		echo; echo "[$scriptName][ERRMSG][ERROR] $1"
	fi
	if [ ! -z "$CDAF_ERROR_DIAG" ]; then
		echo; echo "[$scriptName][ERRMSG]   Invoke custom diag CDAF_ERROR_DIAG = '$CDAF_ERROR_DIAG'"; echo
		eval "$CDAF_ERROR_DIAG"
	fi
	if [ ! -z "$2" ]; then
		echo; echo "[$scriptName][ERRMSG] Exit with LASTEXITCODE = $2" ; echo
		exit $2
	fi
}

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		ERRMSG "$EXECUTABLESCRIPT returned $exitCode" $exitCode
	fi
}
scriptName='build.sh'

echo;echo "[$scriptName] --- start ---"
SOLUTION=$1
if [ -z "$SOLUTION" ]; then
	echo "[$scriptName]   SOLUTION not supplied, exit with code 1."
	exit 1
else
	echo "[$scriptName]   SOLUTION       : $SOLUTION"
fi

BUILDNUMBER=$2
if [ -z "$BUILDNUMBER" ]; then
	echo "[$scriptName]   BUILDNUMBER not supplied, exit with code 2."
	exit 2
else
	echo "[$scriptName]   BUILDNUMBER    : $BUILDNUMBER"
fi

REVISION=$3
if [ -z "$REVISION" ]; then
	echo "[$scriptName]   REVISION       : (not supplied)"
else
	echo "[$scriptName]   REVISION       : $REVISION"
fi

ACTION=$4
if [ -z "$ACTION" ]; then
	echo "[$scriptName]   ACTION         : (not supplied)"
else
	echo "[$scriptName]   ACTION         : $ACTION"
fi

echo; echo 'List Environment Variables'
echo "[$scriptName]   REVISION       = $REVISION"
echo "[$scriptName]   PROJECT        = $PROJECT"
echo "[$scriptName]   SOLUTIONROOT   = $SOLUTIONROOT"
echo "[$scriptName]   AUTOMATIONROOT = $AUTOMATIONROOT"
echo "[$scriptName]   CDAF_CORE      = $CDAF_CORE"

echo; echo 'Use executeExpression to replicate the build.tsk logging and exception handling'

executeExpression 'echo "#!/usr/bin/env bash" > binary.sh'
executeExpression 'echo "echo" >> binary.sh'
executeExpression 'echo "echo [binary.sh] Created by custom build script" >> binary.sh'
executeExpression 'chmod +x binary.sh'
executeExpression './binary.sh'

echo; echo "[$scriptName] --- end ---"; echo
