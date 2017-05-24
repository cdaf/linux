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

scriptName='CDAF.sh'

echo "[$scriptName] --- start ---"
echo "[$scriptName]   whoami  : $(whoami)"
runas="$1"
if [ -z "$runas" ]; then
	echo "[$scriptName]   runas   : (not supplied, run as current user $(whoami))"
else
	echo "[$scriptName]   runas   : $runas"
fi

OPT_ARG="$2"
if [ -z "$OPT_ARG" ]; then
	echo "[$scriptName]   OPT_ARG : (not supplied)"
else
	echo "[$scriptName]   OPT_ARG : $OPT_ARG"
fi

echo
echo "[$scriptName] Execute continuous delivery emulation"
echo
if [ -z "$runas" ]; then
	executeExpression "cd /vagrant/"
	executeExpression "./automation/cdEmulate.sh $OPT_ARG"
else
su $runas << EOF
	echo "[$scriptName] cd /vagrant/"
	cd /vagrant/
	echo "[$scriptName] ./automation/cdEmulate.sh $OPT_ARG"
	./automation/cdEmulate.sh $OPT_ARG
EOF
fi

echo "[$scriptName] --- end ---"
exit 0