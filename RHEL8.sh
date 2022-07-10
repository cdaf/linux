#!/usr/bin/env bash
scriptName='RHEL8.sh'

function writeLog {
	echo "[$scriptName][$(date)] $1"
}

function executeExpression {
	writeLog "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		writeLog "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

function executeIgnore {
	writeLog "$1"
	eval $1
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		if [ -z $2 ]; then
			writeLog "$0 : Warning! $EXECUTABLESCRIPT returned $exitCode"
		else
			if [ "$exitCode" == "$2" ]; then
				writeLog "$0 : Warning! $EXECUTABLESCRIPT returned non-zero exit code ${exitCode} but is ignored due to $2 passed as ignored exit code"
			else
				writeLog "$0 : ERROR! $EXECUTABLESCRIPT returned non-zero exit code ${exitCode} and is exiting becuase ignored exist code is $2"
				exit $exitCode
			fi
		fi
	fi
}  

echo; writeLog "--- start ---"
current_user=$(whoami)
if [[ $current_user != 'root' ]]; then
	elevation='sudo'
fi

writeLog "  whoami       : $current_user"

if [ ! -z "$HTTP_PROXY" ]; then
	writeLog "  HTTP_PROXY   : $HTTP_PROXY"
	curlOpt="-x $HTTP_PROXY"
else
	writeLog "  HTTP_PROXY   : (not set)"
fi

executeIgnore "${elevation} rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
executeExpression "${elevation} yum install -y java-11-openjdk-devel"
 
executeExpression "${elevation} yum install -y snapd"
executeExpression "${elevation} systemctl enable --now snapd.socket"
if [ ! -e "/var/lib/snapd/snap" ]; then
	executeExpression "${elevation} ln -s /var/lib/snapd/snap /snap"       # To enable classic snap support, en
fi

# executeExpression "${elevation} snap install powershell --classic"
 
executeExpression "${elevation} snap install --classic eclipse"
 
# Chrome
executeExpression "wget --directory-prefix=/tmp/chrome https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
executeExpression "${elevation} dnf localinstall -y /tmp/chrome/google-chrome-stable_current_x86_64.rpm"

writeLog "--- end ---"
exit 0
