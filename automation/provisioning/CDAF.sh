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

function setRoot {
	for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
		directoryName=${i%%/}
		if [ -f "$directoryName/CDAF.linux" ]; then
			echo $directoryName
		fi
	done
}  

scriptName='CDAF.sh'

echo "[$scriptName] --- start ---"
echo "[$scriptName]   whoami         : $(whoami)"
echo "[$scriptName]   pwd            : $(pwd)"
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

OPT_ARG="$2"
if [ -z "$OPT_ARG" ]; then
	echo "[$scriptName]   OPT_ARG        : (not supplied)"
else
	echo "[$scriptName]   OPT_ARG        : $OPT_ARG"
fi
automationRoot=$(setRoot)
if [ -z "$automationRoot" ]; then
	if [ -d "/vagrant" ]; then
		cd "/vagrant"
		automationRoot=$(setRoot)
	fi
	if [ -z "$automationRoot" ]; then
		automationRoot="automation"
		echo "[$scriptName]   automationRoot : $automationRoot (CDAF.linux not found)"
	else
		echo "[$scriptName]   automationRoot : $automationRoot (CDAF.linux found in /vagrant)"
	fi
else
	echo "[$scriptName]   automationRoot : $automationRoot (CDAF.linux found)"
fi

echo
echo "[$scriptName] Execute continuous delivery emulation"
echo
if [ -z "$runas" ]; then
	executeExpression "cd /vagrant/"
	executeExpression "${automationRoot}/cdEmulate.sh $OPT_ARG"
else
su $runas << EOF
	echo "[$scriptName] cd /vagrant/"
	cd /vagrant/
	echo "[$scriptName] ${automationRoot}/cdEmulate.sh $OPT_ARG"
	${automationRoot}/cdEmulate.sh $OPT_ARG
EOF
fi

echo "[$scriptName] --- end ---"
exit 0