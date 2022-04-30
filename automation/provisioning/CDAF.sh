#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

function setRoot {
	if [ -d "$1" ]; then
		cd $1
		for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
			directoryName=${i%%/}
			if [ -f "$directoryName/CDAF.linux" ]; then
				(cd "$directoryName" && pwd)
			fi
		done
	fi
}  

scriptName='CDAF.sh'

echo "[$scriptName] --- start ---"
runas="$1"
if [ -z "$runas" ]; then
	echo "[$scriptName]   runas          : (not supplied, run as current user $(whoami))"
else
	if [ "$runas" == '.' ]; then
		unset runas
		echo "[$scriptName]   runas          : (passed ., run as current user $(whoami))"
	else
		echo "[$scriptName]   runas          : $runas"
	fi
fi

workspace="$2"
if [ -z "$workspace" ]; then
	workspace='/vagrant/'
	echo "[$scriptName]   workspace      : $workspace (not supplied, set to default)"
else
	echo "[$scriptName]   workspace      : $workspace"
fi

OPT_ARG="$3"
if [ -z "$OPT_ARG" ]; then
	echo "[$scriptName]   OPT_ARG        : (not supplied)"
else
	echo "[$scriptName]   OPT_ARG        : $OPT_ARG"
fi

echo "[$scriptName]   whoami         = $(whoami)"
echo "[$scriptName]   pwd            = $(pwd)"

AUTOMATIONROOT=$(setRoot "/vagrant")
if [ -z "$AUTOMATIONROOT" ]; then
	AUTOMATIONROOT=$(setRoot "/vagrant/automation")
	echo "[$scriptName]   AUTOMATIONROOT = $AUTOMATIONROOT"
	if [ -z "$AUTOMATIONROOT" ]; then
		echo "[$scriptName] AUTOMATIONROOT cannot be found!"
		exit 7755
	fi
else
	echo "[$scriptName]   AUTOMATIONROOT = $AUTOMATIONROOT"
fi

echo
cat "${AUTOMATIONROOT}/CDAF.linux" | grep productVersion
if [ "$?" != "0" ]; then
	echo "$0 : Exception! CDAF productVersion not found"
	exit $exitCode
fi

echo; echo "[$scriptName] Execute continuous delivery emulation"; echo
if [ -z "$runas" ]; then
	executeExpression "cd $workspace"
	executeExpression "${AUTOMATIONROOT}/cdEmulate.sh $OPT_ARG"
else
su $runas << EOF
	echo "[$scriptName] cd $workspace"
	cd $workspace
	echo "[$scriptName] ${AUTOMATIONROOT}/cdEmulate.sh $OPT_ARG"
	${AUTOMATIONROOT}/cdEmulate.sh $OPT_ARG
EOF
fi

echo "[$scriptName] --- end ---"
exit 0